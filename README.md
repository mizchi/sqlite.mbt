# sqlite.mbt

SQLite database bindings for MoonBit - supports both **native** (C FFI) and **JavaScript** (Node.js) targets.

## Features

- Database management (open, close)
- SQL execution
- Type-safe prepared statements with `SqlValue` enum
- Array-based parameter binding with `bind_all()`
- Iterator-based query results with `iter()`
- Transaction support (BEGIN, COMMIT, ROLLBACK, SAVEPOINT)
- UTF-8 text encoding
- Cross-target compatibility (native and js)

## Requirements

### Native target

- libsqlite3
  - Ubuntu: `apt install libsqlite3-dev`
  - macOS: Pre-installed

### JavaScript target

- Node.js 22.5.0+ (requires `node:sqlite` built-in module)

## Installation

```bash
moon add mizchi/sqlite
```

Add to your `moon.pkg.json`:

```json
{
  "import": ["mizchi/sqlite"],
  "link": {
    "native": {
      "cc-link-flags": "-lsqlite3"
    }
  }
}
```

## Example Usage

```moonbit
let db = @sqlite.Database::open(":memory:").unwrap()

// Create table
db.exec("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)")
|> ignore

// Insert data
db.exec("INSERT INTO users (name, age) VALUES ('Alice', 30)") |> ignore
db.exec("INSERT INTO users (name, age) VALUES ('Bob', 25)") |> ignore

// Query with prepared statement
let stmt = db.prepare("SELECT id, name, age FROM users ORDER BY id").unwrap()
while stmt.step() {
  let id = stmt.column_int(0)
  let name = @encoding.decoder(UTF8).decode_lossy(stmt.column_text(1)[:])
  let age = stmt.column_int(2)
  println("id=\{id}, name=\{name}, age=\{age}")
}
stmt.finalize()

// Query with bind parameter
let stmt2 = db.prepare("SELECT name FROM users WHERE age > ?").unwrap()
stmt2.bind(1, @sqlite.SqlValue::Int(28)) |> ignore
while stmt2.step() {
  let name = @encoding.decoder(UTF8).decode_lossy(stmt2.column_text(0)[:])
  println("\{name}")
}
stmt2.finalize()

db.close()
```

## Build & Test

```bash
# Native target
moon build --target native
moon test --target native

# JavaScript target
moon build --target js
moon test --target js
```

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
- `Database::begin_immediate(self) -> Bool` - Begin immediate transaction
- `Database::begin_exclusive(self) -> Bool` - Begin exclusive transaction
- `Database::commit(self) -> Bool` - Commit transaction
- `Database::rollback(self) -> Bool` - Rollback transaction
- `Database::savepoint(self, name: String) -> Bool` - Create savepoint
- `Database::release(self, name: String) -> Bool` - Release savepoint
- `Database::rollback_to(self, name: String) -> Bool` - Rollback to savepoint

**Statement operations:**
- `Statement::bind(idx: Int, value: SqlValue) -> Bool` - Bind single parameter
- `Statement::bind_all(values: Array[SqlValue]) -> Bool` - Bind all parameters at once
- `Statement::execute() -> Bool` - Execute INSERT/UPDATE/DELETE
- `Statement::step() -> Bool` - Step to next row (for SELECT)
- `Statement::column(col: Int) -> SqlValue` - Get column value as SqlValue
- `Statement::column_int(col: Int) -> Int` - Get column as Int
- `Statement::column_text(col: Int) -> Bytes` - Get column as Bytes
- `Statement::column_count() -> Int` - Get number of columns
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

### Target Compatibility

| API | Native | JS | Notes |
|-----|--------|-----|-------|
| `Database::open` | ✅ | ✅ | |
| `Database::close` | ✅ | ✅ | |
| `Database::exec` | ✅ | ✅ | |
| `Database::prepare` | ✅ | ✅ | |
| `Database::query` | ✅ | ✅ | |
| `Database::begin` | ✅ | ✅ | |
| `Database::commit` | ✅ | ✅ | |
| `Database::rollback` | ✅ | ✅ | |
| `Database::savepoint` | ✅ | ✅ | |
| `Database::changes` | ✅ | ✅ | JS uses `SELECT changes()` |
| `Database::last_insert_rowid` | ✅ | ✅ | JS uses `SELECT last_insert_rowid()` |
| `Database::total_changes` | ✅ | ✅ | JS uses `SELECT total_changes()` |
| `Database::errcode` | ✅ | ⚠️ | JS always returns 0 |
| `Database::errmsg` | ✅ | ⚠️ | JS always returns empty |
| `Database::extended_errcode` | ✅ | ⚠️ | JS always returns 0 |
| `Database::busy_timeout` | ✅ | ⚠️ | JS always returns false |
| `Database::get_autocommit` | ✅ | ⚠️ | JS always returns true |
| `Statement::bind` | ✅ | ✅ | |
| `Statement::bind_all` | ✅ | ✅ | |
| `Statement::execute` | ✅ | ✅ | |
| `Statement::step` | ✅ | ✅ | |
| `Statement::column` | ✅ | ✅ | Integer type differs (see below) |
| `Statement::column_int` | ✅ | ✅ | |
| `Statement::column_text` | ✅ | ✅ | |
| `Statement::column_count` | ✅ | ✅ | |
| `Statement::iter` | ✅ | ✅ | |
| `Statement::reset` | ✅ | ✅ | |
| `Statement::finalize` | ✅ | ✅ | |

### Known Differences

1. **Integer column type**: Native returns `Int64`, JS returns `Int` for integer columns via `column()`.

2. **Int64 binding**: Node.js SQLite doesn't support BigInt as bind parameter. Int64 values are converted to Number (may lose precision for very large integers).

3. **Error handling**: JS target has limited error information. Use try-catch for JS error handling.

4. **Low-level API**: Native target exposes low-level C FFI functions (e.g., `sqlite_*`). These are not available on JS target.

## License

MIT License
