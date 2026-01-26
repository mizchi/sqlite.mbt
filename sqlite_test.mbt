// Cross-target SQLite tests
// These tests should produce identical output on both native and js targets

///|
fn bytes_to_str(b : Bytes) -> String {
  let sb = StringBuilder::new()
  try {
    @encoding.decode_to(b[:], sb, encoding=UTF8)
  } catch {
    _ => ()
  }
  sb.to_string()
}

///|
test "basic: open and close" {
  let db = Database::open(":memory:")
  inspect!(db is None, content="false")
  match db {
    Some(db) => db.close()
    None => ()
  }
}

///|
test "basic: create table and insert" {
  let db = Database::open(":memory:").unwrap()
  let ok = db.exec("CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)")
  inspect!(ok, content="true")
  let ok2 = db.exec("INSERT INTO test (name) VALUES ('Alice')")
  inspect!(ok2, content="true")
  db.close()
}

///|
test "basic: select single row" {
  let db = Database::open(":memory:").unwrap()
  db.exec("CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)") |> ignore
  db.exec("INSERT INTO test (name) VALUES ('Alice')") |> ignore
  let stmt = db.prepare("SELECT id, name FROM test").unwrap()
  inspect!(stmt.step(), content="true")
  inspect!(stmt.column_int(0), content="1")
  let name = bytes_to_str(stmt.column_text(1))
  inspect!(name, content="Alice")
  stmt.finalize()
  db.close()
}

///|
test "basic: select multiple rows" {
  let db = Database::open(":memory:").unwrap()
  db.exec("CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)") |> ignore
  db.exec("INSERT INTO test (name) VALUES ('Alice')") |> ignore
  db.exec("INSERT INTO test (name) VALUES ('Bob')") |> ignore
  db.exec("INSERT INTO test (name) VALUES ('Charlie')") |> ignore
  let stmt = db.prepare("SELECT name FROM test ORDER BY id").unwrap()
  let names : Array[String] = []
  while stmt.step() {
    names.push(bytes_to_str(stmt.column_text(0)))
  }
  inspect!(names, content="[\"Alice\", \"Bob\", \"Charlie\"]")
  stmt.finalize()
  db.close()
}

///|
test "basic: bind parameters" {
  let db = Database::open(":memory:").unwrap()
  db.exec("CREATE TABLE test (id INTEGER PRIMARY KEY, value INTEGER)") |> ignore
  let stmt = db.prepare("INSERT INTO test (value) VALUES (?)").unwrap()
  stmt.bind(1, @core.SqlValue::Int(42)) |> ignore
  stmt.execute() |> ignore
  stmt.finalize()
  let query = db.prepare("SELECT value FROM test").unwrap()
  query.step() |> ignore
  inspect!(query.column_int(0), content="42")
  query.finalize()
  db.close()
}

///|
test "basic: column count" {
  let db = Database::open(":memory:").unwrap()
  db.exec("CREATE TABLE test (a INTEGER, b TEXT, c REAL)") |> ignore
  let stmt = db.prepare("SELECT a, b, c FROM test").unwrap()
  inspect!(stmt.column_count(), content="3")
  stmt.finalize()
  db.close()
}

///|
test "basic: transaction" {
  let db = Database::open(":memory:").unwrap()
  db.exec("CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)") |> ignore
  db.begin() |> ignore
  db.exec("INSERT INTO test (name) VALUES ('Alice')") |> ignore
  db.exec("INSERT INTO test (name) VALUES ('Bob')") |> ignore
  db.commit() |> ignore
  let stmt = db.prepare("SELECT COUNT(*) FROM test").unwrap()
  stmt.step() |> ignore
  inspect!(stmt.column_int(0), content="2")
  stmt.finalize()
  db.close()
}

///|
test "basic: rollback" {
  let db = Database::open(":memory:").unwrap()
  db.exec("CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)") |> ignore
  db.exec("INSERT INTO test (name) VALUES ('Initial')") |> ignore
  db.begin() |> ignore
  db.exec("INSERT INTO test (name) VALUES ('ToBeCancelled')") |> ignore
  db.rollback() |> ignore
  let stmt = db.prepare("SELECT COUNT(*) FROM test").unwrap()
  stmt.step() |> ignore
  inspect!(stmt.column_int(0), content="1")
  stmt.finalize()
  db.close()
}

///|
test "basic: iter" {
  let db = Database::open(":memory:").unwrap()
  db.exec("CREATE TABLE test (id INTEGER PRIMARY KEY, value INTEGER)") |> ignore
  db.exec("INSERT INTO test (value) VALUES (10)") |> ignore
  db.exec("INSERT INTO test (value) VALUES (20)") |> ignore
  db.exec("INSERT INTO test (value) VALUES (30)") |> ignore
  let stmt = db.prepare("SELECT value FROM test ORDER BY id").unwrap()
  let values = stmt.iter().map(fn(s) { s.column_int(0) }).collect()
  inspect!(values, content="[10, 20, 30]")
  stmt.finalize()
  db.close()
}
