# sqlite.mbt

SQLite database bindings for MoonBit - C FFI wrapper for SQLite3.

## Features

- Database management (open, close)
- SQL execution
- Prepared statements
- Parameter binding (int, text)
- Query results iteration
- UTF-8 text encoding

## Usage

```moonbit
let db = match Database::open(":memory:") {
  Some(d) => d
  None => {
    println("Failed to open database")
    return
  }
}

// Create table
db.exec("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)")

// Insert data
db.exec("INSERT INTO users (name, age) VALUES ('Alice', 30)")

// Query with prepared statement
match db.prepare("SELECT id, name, age FROM users") {
  Some(stmt) => {
    while sqlite_step(stmt) == SQLITE_ROW {
      let id = sqlite_column_int(stmt, 0)
      let age = sqlite_column_int(stmt, 2)
      println("id=\{id}, age=\{age}")
    }
    sqlite_finalize(stmt)
  }
  None => println("Failed to prepare statement")
}

db.close()
```

## Requirements

- SQLite3 library installed on your system
- Linked with `-lsqlite3` flag

## API

### High-level API

- `Database::open(path: String) -> Database?` - Open database
- `Database::close(self)` - Close database
- `Database::exec(self, sql: String) -> Bool` - Execute SQL
- `Database::prepare(self, sql: String) -> Sqlite3Stmt?` - Prepare statement

### Low-level API

- `sqlite_open(filename: Bytes) -> Sqlite3`
- `sqlite_close(db: Sqlite3)`
- `sqlite_exec(db: Sqlite3, sql: Bytes) -> Int`
- `sqlite_prepare(db: Sqlite3, sql: Bytes) -> Sqlite3Stmt`
- `sqlite_bind_int(stmt: Sqlite3Stmt, idx: Int, value: Int) -> Int`
- `sqlite_bind_text(stmt: Sqlite3Stmt, idx: Int, text: Bytes) -> Int`
- `sqlite_step(stmt: Sqlite3Stmt) -> Int`
- `sqlite_column_int(stmt: Sqlite3Stmt, col: Int) -> Int`
- `sqlite_column_text(stmt: Sqlite3Stmt, col: Int) -> Bytes`
- `sqlite_reset(stmt: Sqlite3Stmt)`
- `sqlite_finalize(stmt: Sqlite3Stmt)`

## License

MIT License
