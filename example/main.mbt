fn main {
  // Open in-memory database
  let db = @sqlite.Database::open(":memory:").unwrap()

  // Create table
  db.exec("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)")
  |> ignore

  // Insert data
  db.exec("INSERT INTO users (name, age) VALUES ('Alice', 30)") |> ignore
  db.exec("INSERT INTO users (name, age) VALUES ('Bob', 25)") |> ignore
  db.exec("INSERT INTO users (name, age) VALUES ('Charlie', 35)") |> ignore

  // Query with prepared statement
  let stmt = db.prepare("SELECT id, name, age FROM users ORDER BY id").unwrap()

  println("Users:")
  while stmt.step() {
    let id = stmt.column_int(0)
    let name = @encoding.decoder(UTF8).decode_lossy(stmt.column_text(1)[:])
    let age = stmt.column_int(2)
    println("  id=\{id}, name=\{name}, age=\{age}")
  }
  stmt.finalize()

  // Query with bind parameter
  let stmt2 = db.prepare("SELECT name FROM users WHERE age > ?").unwrap()
  stmt2.bind(1, @sqlite.SqlValue::Int(28)) |> ignore

  println("\nUsers older than 28:")
  while stmt2.step() {
    let name = @encoding.decoder(UTF8).decode_lossy(stmt2.column_text(0)[:])
    println("  \{name}")
  }
  stmt2.finalize()

  db.close()
  println("\nDone!")
}
