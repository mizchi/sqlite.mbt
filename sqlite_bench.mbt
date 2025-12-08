// MoonBit SQLite Benchmark
// Run with: moon bench --target native

///|
fn setup_database() -> Database {
  let db = Database::open(":memory:").unwrap()
  db.exec(
    "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL, age INTEGER NOT NULL)",
  )
  |> ignore
  db
}

///|
/// Database Open/Close
test "bench: Database Open/Close" (b : @bench.T) {
  b.bench(fn() {
    let db = Database::open(":memory:").unwrap()
    db.close()
  })
}

///|
/// Create Table
test "bench: Create Table" (b : @bench.T) {
  b.bench(fn() {
    let db = Database::open(":memory:").unwrap()
    db.exec(
      "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL, age INTEGER NOT NULL)",
    )
    |> ignore
    db.close()
  })
}

///|
/// Insert Single Row
test "bench: Insert Single Row" (b : @bench.T) {
  b.bench(fn() {
    let db = setup_database()
    let stmt = db
      .prepare("INSERT INTO users (name, age) VALUES (?, ?)")
      .unwrap()
    sqlite_bind_text(stmt, 1, to_c_string("Alice")) |> ignore
    sqlite_bind_int(stmt, 2, 30) |> ignore
    sqlite_step(stmt) |> ignore
    sqlite_finalize(stmt)
    db.close()
  })
}

///|
/// Insert 100 Rows
test "bench: Insert 100 Rows" (b : @bench.T) {
  b.bench(fn() {
    let db = setup_database()
    let stmt = db
      .prepare("INSERT INTO users (name, age) VALUES (?, ?)")
      .unwrap()
    for i = 0; i < 100; i = i + 1 {
      sqlite_bind_text(stmt, 1, to_c_string("User\{i}")) |> ignore
      sqlite_bind_int(stmt, 2, 20 + i % 50) |> ignore
      sqlite_step(stmt) |> ignore
      sqlite_reset(stmt)
    }
    sqlite_finalize(stmt)
    db.close()
  })
}

///|
/// Insert with Transaction (100 rows)
test "bench: Insert with Transaction (100 rows)" (b : @bench.T) {
  b.bench(fn() {
    let db = setup_database()
    db.begin() |> ignore
    let stmt = db
      .prepare("INSERT INTO users (name, age) VALUES (?, ?)")
      .unwrap()
    for i = 0; i < 100; i = i + 1 {
      sqlite_bind_text(stmt, 1, to_c_string("User\{i}")) |> ignore
      sqlite_bind_int(stmt, 2, 20 + i % 50) |> ignore
      sqlite_step(stmt) |> ignore
      sqlite_reset(stmt)
    }
    sqlite_finalize(stmt)
    db.commit() |> ignore
    db.close()
  })
}

///|
/// Select All Rows
test "bench: Select All Rows" (b : @bench.T) {
  b.bench(fn() {
    let db = setup_database()
    // Insert test data
    let insert_stmt = db
      .prepare("INSERT INTO users (name, age) VALUES (?, ?)")
      .unwrap()
    for i = 0; i < 100; i = i + 1 {
      sqlite_bind_text(insert_stmt, 1, to_c_string("User\{i}")) |> ignore
      sqlite_bind_int(insert_stmt, 2, 20 + i % 50) |> ignore
      sqlite_step(insert_stmt) |> ignore
      sqlite_reset(insert_stmt)
    }
    sqlite_finalize(insert_stmt)
    // Select all
    let select_stmt = db.prepare("SELECT * FROM users").unwrap()
    while sqlite_step(select_stmt) == SQLITE_ROW {
      sqlite_column_int(select_stmt, 0) |> ignore
      sqlite_column_text(select_stmt, 1) |> ignore
      sqlite_column_int(select_stmt, 2) |> ignore
    }
    sqlite_finalize(select_stmt)
    db.close()
  })
}

///|
/// Select with WHERE clause
test "bench: Select with WHERE clause" (b : @bench.T) {
  b.bench(fn() {
    let db = setup_database()
    // Insert test data
    let insert_stmt = db
      .prepare("INSERT INTO users (name, age) VALUES (?, ?)")
      .unwrap()
    for i = 0; i < 100; i = i + 1 {
      sqlite_bind_text(insert_stmt, 1, to_c_string("User\{i}")) |> ignore
      sqlite_bind_int(insert_stmt, 2, 20 + i % 50) |> ignore
      sqlite_step(insert_stmt) |> ignore
      sqlite_reset(insert_stmt)
    }
    sqlite_finalize(insert_stmt)
    // Select with WHERE
    let select_stmt = db.prepare("SELECT * FROM users WHERE age > ?").unwrap()
    sqlite_bind_int(select_stmt, 1, 30) |> ignore
    while sqlite_step(select_stmt) == SQLITE_ROW {
      sqlite_column_int(select_stmt, 0) |> ignore
      sqlite_column_text(select_stmt, 1) |> ignore
      sqlite_column_int(select_stmt, 2) |> ignore
    }
    sqlite_finalize(select_stmt)
    db.close()
  })
}

///|
/// Update Rows
test "bench: Update Rows" (b : @bench.T) {
  b.bench(fn() {
    let db = setup_database()
    // Insert test data
    let insert_stmt = db
      .prepare("INSERT INTO users (name, age) VALUES (?, ?)")
      .unwrap()
    for i = 0; i < 100; i = i + 1 {
      sqlite_bind_text(insert_stmt, 1, to_c_string("User\{i}")) |> ignore
      sqlite_bind_int(insert_stmt, 2, 20 + i % 50) |> ignore
      sqlite_step(insert_stmt) |> ignore
      sqlite_reset(insert_stmt)
    }
    sqlite_finalize(insert_stmt)
    // Update
    let update_stmt = db
      .prepare("UPDATE users SET age = ? WHERE age > ?")
      .unwrap()
    sqlite_bind_int(update_stmt, 1, 25) |> ignore
    sqlite_bind_int(update_stmt, 2, 30) |> ignore
    sqlite_step(update_stmt) |> ignore
    sqlite_finalize(update_stmt)
    db.close()
  })
}

///|
/// Delete Rows
test "bench: Delete Rows" (b : @bench.T) {
  b.bench(fn() {
    let db = setup_database()
    // Insert test data
    let insert_stmt = db
      .prepare("INSERT INTO users (name, age) VALUES (?, ?)")
      .unwrap()
    for i = 0; i < 100; i = i + 1 {
      sqlite_bind_text(insert_stmt, 1, to_c_string("User\{i}")) |> ignore
      sqlite_bind_int(insert_stmt, 2, 20 + i % 50) |> ignore
      sqlite_step(insert_stmt) |> ignore
      sqlite_reset(insert_stmt)
    }
    sqlite_finalize(insert_stmt)
    // Delete
    let delete_stmt = db.prepare("DELETE FROM users WHERE age > ?").unwrap()
    sqlite_bind_int(delete_stmt, 1, 40) |> ignore
    sqlite_step(delete_stmt) |> ignore
    sqlite_finalize(delete_stmt)
    db.close()
  })
}

///|
/// Prepared Statement Reuse
test "bench: Prepared Statement Reuse" (b : @bench.T) {
  b.bench(fn() {
    let db = setup_database()
    let stmt = db
      .prepare("INSERT INTO users (name, age) VALUES (?, ?)")
      .unwrap()
    for i = 0; i < 50; i = i + 1 {
      sqlite_bind_text(stmt, 1, to_c_string("User\{i}")) |> ignore
      sqlite_bind_int(stmt, 2, 20 + i) |> ignore
      sqlite_step(stmt) |> ignore
      sqlite_reset(stmt)
    }
    sqlite_finalize(stmt)
    db.close()
  })
}
