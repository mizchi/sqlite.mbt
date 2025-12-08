# sqlite.mbt

SQLite database bindings for MoonBit - C FFI wrapper for SQLite3.

## Features

- Database management (open, close)
- SQL execution
- Type-safe prepared statements with `SqlValue` enum
- Array-based parameter binding with `bind_all()`
- Iterator-based query results with `iter()`
- Transaction support (BEGIN, COMMIT, ROLLBACK, SAVEPOINT)
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

// Insert data with bind_all()
match db.prepare("INSERT INTO users (name, age) VALUES (?, ?)") {
  Some(stmt) => {
    stmt.bind_all([Text(cstring("Alice")), Int(30)]) |> ignore
    stmt.execute() |> ignore
    stmt.finalize()
  }
  None => println("Failed to prepare statement")
}

// Query with iterator
match db.query("SELECT id, name, age FROM users") {
  Some(stmt) => {
    for row in stmt.iter() {
      let id = row.column_int(0)
      let age = row.column_int(2)
      println("id=\{id}, age=\{age}")
    }
    stmt.finalize()
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

**Database operations:**
- `Database::open(path: String) -> Database?` - Open database
- `Database::close(self)` - Close database
- `Database::exec(self, sql: String) -> Bool` - Execute SQL
- `Database::prepare(self, sql: String) -> Statement?` - Prepare statement
- `Database::query(self, sql: String) -> Statement?` - Prepare SELECT statement

**Transaction API:**
- `Database::begin(self) -> Bool` - Begin transaction
- `Database::commit(self) -> Bool` - Commit transaction
- `Database::rollback(self) -> Bool` - Rollback transaction
- `Database::savepoint(self, name: String) -> Bool` - Create savepoint
- `Database::release(self, name: String) -> Bool` - Release savepoint

**Statement operations:**
- `Statement::bind(idx: Int, value: SqlValue) -> Bool` - Bind single parameter
- `Statement::bind_all(values: Array[SqlValue]) -> Bool` - Bind all parameters at once
- `Statement::execute() -> Bool` - Execute INSERT/UPDATE/DELETE
- `Statement::step() -> Bool` - Step to next row (for SELECT)
- `Statement::column(col: Int) -> SqlValue` - Get column value as SqlValue
- `Statement::column_int(col: Int) -> Int` - Get column as Int
- `Statement::column_text(col: Int) -> Bytes` - Get column as Bytes
- `Statement::iter() -> Iter[Statement]` - Create iterator for query results
- `Statement::reset()` - Reset statement
- `Statement::finalize()` - Finalize statement

**SqlValue enum:**
```moonbit
pub enum SqlValue {
  Null
  Int(Int)
  Int64(Int64)
  Double(Double)
  Text(Bytes)
  Blob(Bytes)
}
```

### Low-level API

Available for advanced usage. See source code for complete list.

## License

MIT License
