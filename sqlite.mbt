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
pub extern "C" fn sqlite_prepare(db : Sqlite3, sql : Bytes) -> Sqlite3Stmt = "sqlite_prepare"

///|
#borrow(stmt)
pub extern "C" fn sqlite_stmt_is_null(stmt : Sqlite3Stmt) -> Int = "sqlite_stmt_is_null"

///|
#borrow(stmt)
pub extern "C" fn sqlite_finalize(stmt : Sqlite3Stmt) -> Unit = "sqlite_finalize"

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
pub extern "C" fn sqlite_step(stmt : Sqlite3Stmt) -> Int = "sqlite_step"

///|
#borrow(stmt)
pub extern "C" fn sqlite_column_int(stmt : Sqlite3Stmt, col : Int) -> Int = "sqlite_column_int"

///|
#borrow(stmt)
pub extern "C" fn sqlite_column_text(stmt : Sqlite3Stmt, col : Int) -> Bytes = "sqlite_column_text"

///|
#borrow(stmt)
extern "C" fn sqlite_reset(stmt : Sqlite3Stmt) -> Unit = "sqlite_reset"

// エラーハンドリング

///|
#borrow(db)
pub extern "C" fn sqlite_errcode(db : Sqlite3) -> Int = "sqlite_errcode"

///|
#borrow(db)
pub extern "C" fn sqlite_errmsg(db : Sqlite3) -> Bytes = "sqlite_errmsg"

///|
#borrow(db)
pub extern "C" fn sqlite_extended_errcode(db : Sqlite3) -> Int = "sqlite_extended_errcode"

///|
pub extern "C" fn sqlite_errstr(errcode : Int) -> Bytes = "sqlite_errstr"

// 追加のバインド関数

///|
#borrow(stmt)
pub extern "C" fn sqlite_bind_null(stmt : Sqlite3Stmt, idx : Int) -> Int = "sqlite_bind_null"

///|
#borrow(stmt)
pub extern "C" fn sqlite_bind_int64(
  stmt : Sqlite3Stmt,
  idx : Int,
  value : Int64,
) -> Int = "sqlite_bind_int64"

///|
#borrow(stmt)
pub extern "C" fn sqlite_bind_double(
  stmt : Sqlite3Stmt,
  idx : Int,
  value : Double,
) -> Int = "sqlite_bind_double"

///|
#borrow(stmt, blob)
pub extern "C" fn sqlite_bind_blob(
  stmt : Sqlite3Stmt,
  idx : Int,
  blob : Bytes,
) -> Int = "sqlite_bind_blob"

// 追加のカラム取得関数

///|
#borrow(stmt)
pub extern "C" fn sqlite_column_int64(stmt : Sqlite3Stmt, col : Int) -> Int64 = "sqlite_column_int64"

///|
#borrow(stmt)
pub extern "C" fn sqlite_column_double(stmt : Sqlite3Stmt, col : Int) -> Double = "sqlite_column_double"

///|
#borrow(stmt)
pub extern "C" fn sqlite_column_blob(stmt : Sqlite3Stmt, col : Int) -> Bytes = "sqlite_column_blob"

///|
#borrow(stmt)
pub extern "C" fn sqlite_column_bytes(stmt : Sqlite3Stmt, col : Int) -> Int = "sqlite_column_bytes"

///|
#borrow(stmt)
pub extern "C" fn sqlite_column_type(stmt : Sqlite3Stmt, col : Int) -> Int = "sqlite_column_type"

// メタデータ関数

///|
#borrow(stmt)
pub extern "C" fn sqlite_column_count(stmt : Sqlite3Stmt) -> Int = "sqlite_column_count"

///|
#borrow(stmt)
pub extern "C" fn sqlite_column_name(stmt : Sqlite3Stmt, col : Int) -> Bytes = "sqlite_column_name"

///|
#borrow(db)
pub extern "C" fn sqlite_changes(db : Sqlite3) -> Int = "sqlite_changes"

///|
#borrow(db)
pub extern "C" fn sqlite_last_insert_rowid(db : Sqlite3) -> Int64 = "sqlite_last_insert_rowid"

// ステートメントクリア

///|
#borrow(stmt)
pub extern "C" fn sqlite_clear_bindings(stmt : Sqlite3Stmt) -> Int = "sqlite_clear_bindings"

// 並行アクセス制御

///|
#borrow(db)
pub extern "C" fn sqlite_busy_timeout(db : Sqlite3, ms : Int) -> Int = "sqlite_busy_timeout"

// トランザクション管理

///|
#borrow(db)
pub extern "C" fn sqlite_get_autocommit(db : Sqlite3) -> Int = "sqlite_get_autocommit"

///|
#borrow(db)
pub extern "C" fn sqlite_total_changes(db : Sqlite3) -> Int = "sqlite_total_changes"

// ステートメント Introspection

///|
#borrow(stmt)
pub extern "C" fn sqlite_sql(stmt : Sqlite3Stmt) -> Bytes = "sqlite_sql"

///|
#borrow(stmt)
pub extern "C" fn sqlite_bind_parameter_count(stmt : Sqlite3Stmt) -> Int = "sqlite_bind_parameter_count"

///|
#borrow(stmt)
pub extern "C" fn sqlite_stmt_readonly(stmt : Sqlite3Stmt) -> Int = "sqlite_stmt_readonly"

// パラメータ名とインデックス

///|
#borrow(stmt)
pub extern "C" fn sqlite_bind_parameter_name(
  stmt : Sqlite3Stmt,
  idx : Int,
) -> Bytes = "sqlite_bind_parameter_name"

///|
#borrow(stmt, name)
pub extern "C" fn sqlite_bind_parameter_index(
  stmt : Sqlite3Stmt,
  name : Bytes,
) -> Int = "sqlite_bind_parameter_index"

// 定数

///|
const SQLITE_OK : Int = 0

///|
pub const SQLITE_ROW : Int = 100

///|
pub const SQLITE_DONE : Int = 101

// SQLite型定数
///|
pub const SQLITE_INTEGER : Int = 1

///|
pub const SQLITE_FLOAT : Int = 2

///|
pub const SQLITE_TEXT : Int = 3

///|
pub const SQLITE_BLOB : Int = 4

///|
pub const SQLITE_NULL : Int = 5

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
pub fn Database::errcode(self : Database) -> Int {
  sqlite_errcode(self.handle)
}

///|
pub fn Database::errmsg(self : Database) -> Bytes {
  sqlite_errmsg(self.handle)
}

///|
pub fn Database::extended_errcode(self : Database) -> Int {
  sqlite_extended_errcode(self.handle)
}

///|
pub fn Database::changes(self : Database) -> Int {
  sqlite_changes(self.handle)
}

///|
pub fn Database::last_insert_rowid(self : Database) -> Int64 {
  sqlite_last_insert_rowid(self.handle)
}

///|
pub fn Database::busy_timeout(self : Database, ms : Int) -> Bool {
  sqlite_busy_timeout(self.handle, ms) == SQLITE_OK
}

///|
pub fn Database::get_autocommit(self : Database) -> Bool {
  sqlite_get_autocommit(self.handle) != 0
}

///|
pub fn Database::total_changes(self : Database) -> Int {
  sqlite_total_changes(self.handle)
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

///|
test "database_integration" {
  // メモリ上にデータベースを作成
  let db = match Database::open(":memory:") {
    Some(d) => d
    None => {
      abort("Failed to open database")
    }
  }

  // テーブル作成
  let ok = db.exec(
    "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)",
  )
  assert_true(ok)

  // データ挿入
  assert_true(db.exec("INSERT INTO users (name, age) VALUES ('Alice', 30)"))
  assert_true(db.exec("INSERT INTO users (name, age) VALUES ('Bob', 25)"))

  // クエリ実行
  match db.prepare("SELECT id, name, age FROM users") {
    Some(stmt) => {
      // 1件目: Alice
      assert_eq(sqlite_step(stmt), SQLITE_ROW)
      assert_eq(sqlite_column_int(stmt, 0), 1)
      assert_eq(sqlite_column_int(stmt, 2), 30)

      // 2件目: Bob
      assert_eq(sqlite_step(stmt), SQLITE_ROW)
      assert_eq(sqlite_column_int(stmt, 0), 2)
      assert_eq(sqlite_column_int(stmt, 2), 25)

      sqlite_finalize(stmt)
    }
    None => abort("Failed to prepare statement")
  }
  db.close()
}

///|
test "sqlite_bind_double" {
  let db = sqlite_open(to_c_string(":memory:"))
  let _ = sqlite_exec(db, to_c_string("CREATE TABLE t (id INTEGER, value REAL)"))
  let stmt = sqlite_prepare(
    db,
    to_c_string("INSERT INTO t (id, value) VALUES (?, ?)"),
  )
  let _ = sqlite_bind_int(stmt, 1, 1)
  let _ = sqlite_bind_double(stmt, 2, 3.14)
  let _ = sqlite_step(stmt)
  sqlite_finalize(stmt)

  // 確認
  let stmt2 = sqlite_prepare(db, to_c_string("SELECT value FROM t WHERE id = 1"))
  assert_eq(sqlite_step(stmt2), SQLITE_ROW)
  let val = sqlite_column_double(stmt2, 0)
  assert_true(val > 3.13 && val < 3.15)
  sqlite_finalize(stmt2)
  sqlite_close(db)
}

///|
test "sqlite_bind_null" {
  let db = sqlite_open(to_c_string(":memory:"))
  let _ = sqlite_exec(db, to_c_string("CREATE TABLE t (id INTEGER, value TEXT)"))
  let stmt = sqlite_prepare(
    db,
    to_c_string("INSERT INTO t (id, value) VALUES (?, ?)"),
  )
  let _ = sqlite_bind_int(stmt, 1, 1)
  let _ = sqlite_bind_null(stmt, 2)
  let _ = sqlite_step(stmt)
  sqlite_finalize(stmt)

  // NULL値を確認
  let stmt2 = sqlite_prepare(db, to_c_string("SELECT value FROM t WHERE id = 1"))
  assert_eq(sqlite_step(stmt2), SQLITE_ROW)
  assert_eq(sqlite_column_type(stmt2, 0), SQLITE_NULL)
  sqlite_finalize(stmt2)
  sqlite_close(db)
}

///|
test "sqlite_int64" {
  let db = sqlite_open(to_c_string(":memory:"))
  let _ = sqlite_exec(db, to_c_string("CREATE TABLE t (id INTEGER, value INTEGER)"))
  let stmt = sqlite_prepare(
    db,
    to_c_string("INSERT INTO t (id, value) VALUES (?, ?)"),
  )
  let _ = sqlite_bind_int(stmt, 1, 1)
  let large_val : Int64 = 9223372036854775807L // Int64::max_value
  let _ = sqlite_bind_int64(stmt, 2, large_val)
  let _ = sqlite_step(stmt)
  sqlite_finalize(stmt)

  // 確認
  let stmt2 = sqlite_prepare(db, to_c_string("SELECT value FROM t WHERE id = 1"))
  assert_eq(sqlite_step(stmt2), SQLITE_ROW)
  assert_eq(sqlite_column_int64(stmt2, 0), large_val)
  sqlite_finalize(stmt2)
  sqlite_close(db)
}

///|
test "sqlite_bind_blob" {
  let db = sqlite_open(to_c_string(":memory:"))
  let _ = sqlite_exec(db, to_c_string("CREATE TABLE t (id INTEGER, data BLOB)"))
  let stmt = sqlite_prepare(
    db,
    to_c_string("INSERT INTO t (id, data) VALUES (?, ?)"),
  )
  let _ = sqlite_bind_int(stmt, 1, 1)
  let blob_data = to_c_string("binary\u{0000}data")
  let _ = sqlite_bind_blob(stmt, 2, blob_data)
  let _ = sqlite_step(stmt)
  sqlite_finalize(stmt)

  // 確認
  let stmt2 = sqlite_prepare(db, to_c_string("SELECT data FROM t WHERE id = 1"))
  assert_eq(sqlite_step(stmt2), SQLITE_ROW)
  let _ = sqlite_column_blob(stmt2, 0)
  assert_true(sqlite_column_bytes(stmt2, 0) > 0)
  sqlite_finalize(stmt2)
  sqlite_close(db)
}

///|
test "sqlite_column_type" {
  let db = sqlite_open(to_c_string(":memory:"))
  let _ = sqlite_exec(
    db,
    to_c_string("CREATE TABLE t (i INTEGER, r REAL, t TEXT, b BLOB, n TEXT)"),
  )
  let _ = sqlite_exec(
    db,
    to_c_string("INSERT INTO t VALUES (42, 3.14, 'hello', X'DEAD', NULL)"),
  )

  let stmt = sqlite_prepare(db, to_c_string("SELECT * FROM t"))
  assert_eq(sqlite_step(stmt), SQLITE_ROW)
  assert_eq(sqlite_column_type(stmt, 0), SQLITE_INTEGER)
  assert_eq(sqlite_column_type(stmt, 1), SQLITE_FLOAT)
  assert_eq(sqlite_column_type(stmt, 2), SQLITE_TEXT)
  assert_eq(sqlite_column_type(stmt, 3), SQLITE_BLOB)
  assert_eq(sqlite_column_type(stmt, 4), SQLITE_NULL)
  sqlite_finalize(stmt)
  sqlite_close(db)
}

///|
test "sqlite_column_count_and_name" {
  let db = sqlite_open(to_c_string(":memory:"))
  let _ = sqlite_exec(
    db,
    to_c_string("CREATE TABLE t (id INTEGER, name TEXT, age INTEGER)"),
  )

  let stmt = sqlite_prepare(db, to_c_string("SELECT id, name, age FROM t"))
  assert_eq(sqlite_column_count(stmt), 3)
  let _ = sqlite_column_name(stmt, 0) // "id"
  let _ = sqlite_column_name(stmt, 1) // "name"
  let _ = sqlite_column_name(stmt, 2) // "age"
  sqlite_finalize(stmt)
  sqlite_close(db)
}

///|
test "sqlite_changes_and_last_insert_rowid" {
  let db = sqlite_open(to_c_string(":memory:"))
  let _ = sqlite_exec(
    db,
    to_c_string("CREATE TABLE t (id INTEGER PRIMARY KEY, value INTEGER)"),
  )

  // 1件挿入
  let stmt = sqlite_prepare(db, to_c_string("INSERT INTO t (value) VALUES (?)"))
  let _ = sqlite_bind_int(stmt, 1, 100)
  let _ = sqlite_step(stmt)
  sqlite_finalize(stmt)

  // 変更数とrowidを確認
  assert_eq(sqlite_changes(db), 1)
  assert_eq(sqlite_last_insert_rowid(db), 1L)

  // もう1件挿入
  let stmt2 = sqlite_prepare(db, to_c_string("INSERT INTO t (value) VALUES (?)"))
  let _ = sqlite_bind_int(stmt2, 1, 200)
  let _ = sqlite_step(stmt2)
  sqlite_finalize(stmt2)

  assert_eq(sqlite_changes(db), 1)
  assert_eq(sqlite_last_insert_rowid(db), 2L)

  sqlite_close(db)
}

///|
test "sqlite_clear_bindings" {
  let db = sqlite_open(to_c_string(":memory:"))
  let _ = sqlite_exec(db, to_c_string("CREATE TABLE t (id INTEGER, value INTEGER)"))
  let stmt = sqlite_prepare(
    db,
    to_c_string("INSERT INTO t (id, value) VALUES (?, ?)"),
  )

  // バインド
  let _ = sqlite_bind_int(stmt, 1, 1)
  let _ = sqlite_bind_int(stmt, 2, 100)

  // クリア
  let _ = sqlite_clear_bindings(stmt)

  // リセットして再バインド
  sqlite_reset(stmt)
  let _ = sqlite_bind_int(stmt, 1, 2)
  let _ = sqlite_bind_int(stmt, 2, 200)
  let _ = sqlite_step(stmt)
  sqlite_finalize(stmt)

  // 確認
  let stmt2 = sqlite_prepare(db, to_c_string("SELECT value FROM t WHERE id = 2"))
  assert_eq(sqlite_step(stmt2), SQLITE_ROW)
  assert_eq(sqlite_column_int(stmt2, 0), 200)
  sqlite_finalize(stmt2)
  sqlite_close(db)
}

///|
test "database_error_handling" {
  let db = match Database::open(":memory:") {
    Some(d) => d
    None => abort("Failed to open database")
  }

  // 正常なクエリ
  assert_true(db.exec("CREATE TABLE t (id INTEGER)"))
  assert_eq(db.errcode(), SQLITE_OK)

  // エラーを引き起こす不正なクエリ
  let ok = db.exec("INVALID SQL SYNTAX")
  assert_false(ok)
  assert_true(db.errcode() != SQLITE_OK)
  let _ = db.errmsg() // エラーメッセージを取得

  db.close()
}

///|
test "sqlite_extended_errcode_and_errstr" {
  let db = sqlite_open(to_c_string(":memory:"))

  // 正常な操作
  let _ = sqlite_exec(db, to_c_string("CREATE TABLE t (id INTEGER)"))
  assert_eq(sqlite_errcode(db), SQLITE_OK)
  assert_eq(sqlite_extended_errcode(db), SQLITE_OK)

  // エラーを引き起こす
  let _ = sqlite_exec(db, to_c_string("INVALID SQL"))
  let errcode = sqlite_errcode(db)
  assert_true(errcode != SQLITE_OK)

  // 拡張エラーコードを取得
  let ext_errcode = sqlite_extended_errcode(db)
  assert_true(ext_errcode != SQLITE_OK)

  // エラーコードから文字列を取得
  let _ = sqlite_errstr(errcode)
  let _ = sqlite_errstr(ext_errcode)
  let _ = sqlite_errstr(SQLITE_OK)

  sqlite_close(db)
}

///|
test "database_changes_and_rowid" {
  let db = match Database::open(":memory:") {
    Some(d) => d
    None => abort("Failed to open database")
  }

  assert_true(
    db.exec("CREATE TABLE t (id INTEGER PRIMARY KEY, value INTEGER)"),
  )

  // 挿入
  assert_true(db.exec("INSERT INTO t (value) VALUES (100)"))
  assert_eq(db.changes(), 1)
  assert_eq(db.last_insert_rowid(), 1L)

  assert_true(db.exec("INSERT INTO t (value) VALUES (200)"))
  assert_eq(db.changes(), 1)
  assert_eq(db.last_insert_rowid(), 2L)

  db.close()
}

///|
test "sqlite_busy_timeout" {
  let db = sqlite_open(to_c_string(":memory:"))
  let rc = sqlite_busy_timeout(db, 1000)
  assert_eq(rc, SQLITE_OK)
  sqlite_close(db)
}

///|
test "sqlite_get_autocommit" {
  let db = sqlite_open(to_c_string(":memory:"))
  assert_true(sqlite_get_autocommit(db) != 0)
  let _ = sqlite_exec(db, to_c_string("BEGIN"))
  assert_eq(sqlite_get_autocommit(db), 0)
  let _ = sqlite_exec(db, to_c_string("COMMIT"))
  assert_true(sqlite_get_autocommit(db) != 0)
  sqlite_close(db)
}

///|
test "sqlite_total_changes" {
  let db = sqlite_open(to_c_string(":memory:"))
  let _ = sqlite_exec(db, to_c_string("CREATE TABLE t (id INTEGER, value INTEGER)"))
  assert_eq(sqlite_total_changes(db), 0)
  let _ = sqlite_exec(db, to_c_string("INSERT INTO t VALUES (1, 100)"))
  let _ = sqlite_exec(db, to_c_string("INSERT INTO t VALUES (2, 200)"))
  let _ = sqlite_exec(db, to_c_string("INSERT INTO t VALUES (3, 300)"))
  assert_eq(sqlite_total_changes(db), 3)
  let _ = sqlite_exec(db, to_c_string("DELETE FROM t WHERE id = 2"))
  assert_eq(sqlite_total_changes(db), 4)
  sqlite_close(db)
}

///|
test "sqlite_sql" {
  let db = sqlite_open(to_c_string(":memory:"))
  let sql_text = "SELECT * FROM sqlite_master"
  let stmt = sqlite_prepare(db, to_c_string(sql_text))
  let _ = sqlite_sql(stmt)
  sqlite_finalize(stmt)
  sqlite_close(db)
}

///|
test "sqlite_bind_parameter_count" {
  let db = sqlite_open(to_c_string(":memory:"))
  let stmt1 = sqlite_prepare(db, to_c_string("SELECT 1"))
  assert_eq(sqlite_bind_parameter_count(stmt1), 0)
  sqlite_finalize(stmt1)
  let stmt2 = sqlite_prepare(db, to_c_string("SELECT ?, ?"))
  assert_eq(sqlite_bind_parameter_count(stmt2), 2)
  sqlite_finalize(stmt2)
  let stmt3 = sqlite_prepare(db, to_c_string("SELECT ?, ?, ?, ?, ?"))
  assert_eq(sqlite_bind_parameter_count(stmt3), 5)
  sqlite_finalize(stmt3)
  sqlite_close(db)
}

///|
test "sqlite_stmt_readonly" {
  let db = sqlite_open(to_c_string(":memory:"))
  let _ = sqlite_exec(db, to_c_string("CREATE TABLE t (id INTEGER)"))
  let stmt1 = sqlite_prepare(db, to_c_string("SELECT * FROM t"))
  assert_true(sqlite_stmt_readonly(stmt1) != 0)
  sqlite_finalize(stmt1)
  let stmt2 = sqlite_prepare(db, to_c_string("INSERT INTO t VALUES (1)"))
  assert_eq(sqlite_stmt_readonly(stmt2), 0)
  sqlite_finalize(stmt2)
  let stmt3 = sqlite_prepare(db, to_c_string("UPDATE t SET id = 2"))
  assert_eq(sqlite_stmt_readonly(stmt3), 0)
  sqlite_finalize(stmt3)
  sqlite_close(db)
}

///|
test "database_busy_timeout" {
  let db = match Database::open(":memory:") {
    Some(d) => d
    None => abort("Failed to open database")
  }
  assert_true(db.busy_timeout(5000))
  db.close()
}

///|
test "database_autocommit_and_total_changes" {
  let db = match Database::open(":memory:") {
    Some(d) => d
    None => abort("Failed to open database")
  }
  assert_true(db.exec("CREATE TABLE t (id INTEGER)"))
  assert_true(db.get_autocommit())
  assert_eq(db.total_changes(), 0)
  assert_true(db.exec("INSERT INTO t VALUES (1)"))
  assert_true(db.exec("INSERT INTO t VALUES (2)"))
  assert_eq(db.total_changes(), 2)
  assert_true(db.exec("BEGIN"))
  assert_false(db.get_autocommit())
  assert_true(db.exec("INSERT INTO t VALUES (3)"))
  assert_eq(db.total_changes(), 3)
  assert_true(db.exec("COMMIT"))
  assert_true(db.get_autocommit())
  db.close()
}

///|
test "sqlite_bind_parameter_name_and_index" {
  let db = sqlite_open(to_c_string(":memory:"))
  let _ = sqlite_exec(db, to_c_string("CREATE TABLE t (id INTEGER, value TEXT)"))

  // 名前付きパラメータを使ったクエリ
  let stmt = sqlite_prepare(
    db,
    to_c_string("INSERT INTO t (id, value) VALUES (:id, :value)"),
  )

  // パラメータ数を確認
  assert_eq(sqlite_bind_parameter_count(stmt), 2)

  // パラメータ名を取得（1-indexed）
  let _ = sqlite_bind_parameter_name(stmt, 1) // ":id"
  let _ = sqlite_bind_parameter_name(stmt, 2) // ":value"

  // パラメータ名からインデックスを取得
  let id_idx = sqlite_bind_parameter_index(stmt, to_c_string(":id"))
  assert_eq(id_idx, 1)
  let value_idx = sqlite_bind_parameter_index(stmt, to_c_string(":value"))
  assert_eq(value_idx, 2)

  // 名前を使ってバインド
  let _ = sqlite_bind_int(stmt, id_idx, 100)
  let _ = sqlite_bind_text(stmt, value_idx, to_c_string("test"))
  let _ = sqlite_step(stmt)

  sqlite_finalize(stmt)
  sqlite_close(db)
}
