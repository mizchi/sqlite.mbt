// SQLite バインディング

// 不透明な外部型（Cのポインタに対応）

///|
type Sqlite3

///|
type Sqlite3Stmt

// 低レベルextern宣言
// #borrow: 引数を借用として扱い、MoonBitが自動的にメモリ管理を行う

///|
#borrow(filename)
extern "C" fn sqlite_open(filename : Bytes) -> Sqlite3 = "sqlite_open"

///|
#borrow(ptr)
extern "C" fn sqlite_is_null(ptr : Sqlite3) -> Int = "sqlite_is_null"

///|
#borrow(db)
extern "C" fn sqlite_close(db : Sqlite3) -> Unit = "sqlite_close"

///|
#borrow(db, sql)
extern "C" fn sqlite_exec(db : Sqlite3, sql : Bytes) -> Int = "sqlite_exec"

///|
#borrow(db, sql)
extern "C" fn sqlite_prepare(db : Sqlite3, sql : Bytes) -> Sqlite3Stmt = "sqlite_prepare"

///|
#borrow(stmt)
extern "C" fn sqlite_stmt_is_null(stmt : Sqlite3Stmt) -> Int = "sqlite_stmt_is_null"

///|
#borrow(stmt)
extern "C" fn sqlite_finalize(stmt : Sqlite3Stmt) -> Unit = "sqlite_finalize"

///|
#borrow(stmt)
extern "C" fn sqlite_bind_int(
  stmt : Sqlite3Stmt,
  idx : Int,
  value : Int,
) -> Int = "sqlite_bind_int"

///|
#borrow(stmt, text)
extern "C" fn sqlite_bind_text(
  stmt : Sqlite3Stmt,
  idx : Int,
  text : Bytes,
) -> Int = "sqlite_bind_text"

///|
#borrow(stmt)
extern "C" fn sqlite_step(stmt : Sqlite3Stmt) -> Int = "sqlite_step"

///|
#borrow(stmt)
extern "C" fn sqlite_column_int(stmt : Sqlite3Stmt, col : Int) -> Int = "sqlite_column_int"

///|
#borrow(stmt)
extern "C" fn sqlite_column_text(stmt : Sqlite3Stmt, col : Int) -> Bytes = "sqlite_column_text"

///|
#borrow(stmt)
extern "C" fn sqlite_reset(stmt : Sqlite3Stmt) -> Unit = "sqlite_reset"

// 定数

///|
const SQLITE_OK : Int = 0

///|
const SQLITE_ROW : Int = 100

// String -> Bytes 変換ヘルパー（UTF-8エンコーディング）
// Using @encoding from moonbitlang/x/encoding

///|
fn to_c_string(s : String) -> Bytes {
  @encoding.encode(UTF8, s)
}

// 高レベルAPI

///|
pub struct Database {
  priv handle : Sqlite3
}

///|
pub fn Database::open(path : String) -> Database? {
  let db = sqlite_open(to_c_string(path))
  if sqlite_is_null(db) == 1 {
    None
  } else {
    Some({ handle: db })
  }
}

///|
pub fn Database::close(self : Database) -> Unit {
  sqlite_close(self.handle)
}

///|
pub fn Database::exec(self : Database, sql : String) -> Bool {
  sqlite_exec(self.handle, to_c_string(sql)) == SQLITE_OK
}

///|
pub fn Database::prepare(self : Database, sql : String) -> Sqlite3Stmt? {
  let stmt = sqlite_prepare(self.handle, to_c_string(sql))
  if sqlite_stmt_is_null(stmt) == 1 {
    None
  } else {
    Some(stmt)
  }
}

///|
fn main {
  println("=== SQLite Demo ===")

  // メモリ上にデータベースを作成
  let db = match Database::open(":memory:") {
    Some(d) => d
    None => {
      println("Failed to open database")
      return
    }
  }
  println("Database opened")

  // テーブル作成
  let ok = db.exec(
    "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)",
  )
  println("CREATE TABLE: \{ok}")

  // データ挿入
  let ok = db.exec("INSERT INTO users (name, age) VALUES ('Alice', 30)")
  println("INSERT Alice: \{ok}")
  let ok = db.exec("INSERT INTO users (name, age) VALUES ('Bob', 25)")
  println("INSERT Bob: \{ok}")

  // クエリ実行
  match db.prepare("SELECT id, name, age FROM users") {
    Some(stmt) => {
      println("Query results:")
      while sqlite_step(stmt) == SQLITE_ROW {
        let id = sqlite_column_int(stmt, 0)
        let age = sqlite_column_int(stmt, 2)
        println("  id=\{id}, age=\{age}")
      }
      sqlite_finalize(stmt)
    }
    None => println("Failed to prepare statement")
  }
  db.close()
  println("Database closed")
}

///|
test "sqlite_open_close" {
  let db = sqlite_open(to_c_string(":memory:"))
  assert_false(sqlite_is_null(db) == 1)
  sqlite_close(db)
}

///|
test "sqlite_exec" {
  let db = sqlite_open(to_c_string(":memory:"))
  let rc = sqlite_exec(db, to_c_string("CREATE TABLE t (id INTEGER)"))
  assert_eq(rc, SQLITE_OK)
  sqlite_close(db)
}

///|
test "sqlite_bind_int" {
  let db = sqlite_open(to_c_string(":memory:"))
  let _ = sqlite_exec(
    db,
    to_c_string("CREATE TABLE t (id INTEGER, value INTEGER)"),
  )

  // プリペアドステートメントでINSERT
  let stmt = sqlite_prepare(
    db,
    to_c_string("INSERT INTO t (id, value) VALUES (?, ?)"),
  )
  assert_false(sqlite_stmt_is_null(stmt) == 1)
  let _ = sqlite_bind_int(stmt, 1, 100)
  let _ = sqlite_bind_int(stmt, 2, 42)
  let _ = sqlite_step(stmt)
  sqlite_finalize(stmt)

  // 確認
  let stmt2 = sqlite_prepare(
    db,
    to_c_string("SELECT value FROM t WHERE id = 100"),
  )
  assert_eq(sqlite_step(stmt2), SQLITE_ROW)
  assert_eq(sqlite_column_int(stmt2, 0), 42)
  sqlite_finalize(stmt2)
  sqlite_close(db)
}

///|
test "sqlite_bind_text" {
  let db = sqlite_open(to_c_string(":memory:"))
  let _ = sqlite_exec(db, to_c_string("CREATE TABLE t (id INTEGER, name TEXT)"))
  let stmt = sqlite_prepare(
    db,
    to_c_string("INSERT INTO t (id, name) VALUES (?, ?)"),
  )
  let _ = sqlite_bind_int(stmt, 1, 1)
  let _ = sqlite_bind_text(stmt, 2, to_c_string("hello"))
  let _ = sqlite_step(stmt)
  sqlite_finalize(stmt)

  // 確認（sqlite_column_textを使用）
  let stmt2 = sqlite_prepare(db, to_c_string("SELECT name FROM t WHERE id = 1"))
  assert_eq(sqlite_step(stmt2), SQLITE_ROW)
  let _ = sqlite_column_text(stmt2, 0) // Bytes型で取得
  sqlite_finalize(stmt2)
  sqlite_close(db)
}

///|
test "sqlite_reset" {
  let db = sqlite_open(to_c_string(":memory:"))
  let _ = sqlite_exec(db, to_c_string("CREATE TABLE t (id INTEGER)"))
  let stmt = sqlite_prepare(db, to_c_string("INSERT INTO t (id) VALUES (?)"))

  // 1回目のINSERT
  let _ = sqlite_bind_int(stmt, 1, 1)
  let _ = sqlite_step(stmt)

  // リセットして再利用
  sqlite_reset(stmt)

  // 2回目のINSERT
  let _ = sqlite_bind_int(stmt, 1, 2)
  let _ = sqlite_step(stmt)
  sqlite_finalize(stmt)

  // 2件挿入されたことを確認
  let stmt2 = sqlite_prepare(db, to_c_string("SELECT COUNT(*) FROM t"))
  let _ = sqlite_step(stmt2)
  assert_eq(sqlite_column_int(stmt2, 0), 2)
  sqlite_finalize(stmt2)
  sqlite_close(db)
}
