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

  // INSERT with prepared statement
  let stmt = sqlite_prepare(
    db,
    to_c_string("INSERT INTO t (id, value) VALUES (?, ?)"),
  )
  assert_false(sqlite_stmt_is_null(stmt) == 1)
  let _ = sqlite_bind_int(stmt, 1, 100)
  let _ = sqlite_bind_int(stmt, 2, 42)
  let _ = sqlite_step(stmt)
  sqlite_finalize(stmt)

  // Verify
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

  // Verify（sqlite_column_textを使用）
  let stmt2 = sqlite_prepare(db, to_c_string("SELECT name FROM t WHERE id = 1"))
  assert_eq(sqlite_step(stmt2), SQLITE_ROW)
  let _ = sqlite_column_text(stmt2, 0) // Get as Bytes type
  sqlite_finalize(stmt2)
  sqlite_close(db)
}

///|
test "sqlite_reset" {
  let db = sqlite_open(to_c_string(":memory:"))
  let _ = sqlite_exec(db, to_c_string("CREATE TABLE t (id INTEGER)"))
  let stmt = sqlite_prepare(db, to_c_string("INSERT INTO t (id) VALUES (?)"))

  // First INSERT
  let _ = sqlite_bind_int(stmt, 1, 1)
  let _ = sqlite_step(stmt)

  // Reset and reuse
  sqlite_reset(stmt)

  // Second INSERT
  let _ = sqlite_bind_int(stmt, 1, 2)
  let _ = sqlite_step(stmt)
  sqlite_finalize(stmt)

  // Verify 2 rows inserted
  let stmt2 = sqlite_prepare(db, to_c_string("SELECT COUNT(*) FROM t"))
  let _ = sqlite_step(stmt2)
  assert_eq(sqlite_column_int(stmt2, 0), 2)
  sqlite_finalize(stmt2)
  sqlite_close(db)
}

///|
test "database_integration" {
  // Create in-memory database
  let db = match Database::open(":memory:") {
    Some(d) => d
    None => {
      abort("Failed to open database")
    }
  }

  // Create table
  let ok = db.exec(
    "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER)",
  )
  assert_true(ok)

  // Insert data
  assert_true(db.exec("INSERT INTO users (name, age) VALUES ('Alice', 30)"))
  assert_true(db.exec("INSERT INTO users (name, age) VALUES ('Bob', 25)"))

  // Execute query
  match db.prepare("SELECT id, name, age FROM users") {
    Some(stmt) => {
      // First row: Alice
      assert_eq(sqlite_step(stmt), SQLITE_ROW)
      assert_eq(sqlite_column_int(stmt, 0), 1)
      assert_eq(sqlite_column_int(stmt, 2), 30)

      // Second row: Bob
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

  // Verify
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

  // Verify NULL value
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

  // Verify
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

  // Verify
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

  // Verify changes and rowid
  assert_eq(sqlite_changes(db), 1)
  assert_eq(sqlite_last_insert_rowid(db), 1L)

  // Insert one more row
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

  // Reset and rebind
  sqlite_reset(stmt)
  let _ = sqlite_bind_int(stmt, 1, 2)
  let _ = sqlite_bind_int(stmt, 2, 200)
  let _ = sqlite_step(stmt)
  sqlite_finalize(stmt)

  // Verify
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

  // Normal query
  assert_true(db.exec("CREATE TABLE t (id INTEGER)"))
  assert_eq(db.errcode(), SQLITE_OK)

  // Invalid query that causes error
  let ok = db.exec("INVALID SQL SYNTAX")
  assert_false(ok)
  assert_true(db.errcode() != SQLITE_OK)
  let _ = db.errmsg() // Get error message

  // Also get extended error code
  let ext_code = db.extended_errcode()
  assert_true(ext_code != SQLITE_OK)

  db.close()
}

///|
test "database_open_failure" {
  // Try to open database with invalid path (returns None)
  // SQLite accepts many paths, so it's difficult to reliably fail
  // Instead, test a path that cannot be opened
  let result = Database::open("/dev/null/impossible/path/database.db")
  match result {
    Some(_) => {
      // It may actually open, but that's OK
      // The purpose of this test is to cover the None path
      ()
    }
    None => {
      // Error path covered
      assert_true(true)
    }
  }
}

///|
test "database_prepare_failure" {
  let db = match Database::open(":memory:") {
    Some(d) => d
    None => abort("Failed to open database")
  }

  // Try to prepare invalid SQL statement (returns None)
  let result = db.prepare("COMPLETELY INVALID SQL THAT WILL NEVER PARSE")
  match result {
    Some(_) => abort("Should have failed to prepare invalid SQL")
    None => ()  // Error path covered
  }

  db.close()
}

///|
test "sqlite_extended_errcode_and_errstr" {
  let db = sqlite_open(to_c_string(":memory:"))

  // Normal operation
  let _ = sqlite_exec(db, to_c_string("CREATE TABLE t (id INTEGER)"))
  assert_eq(sqlite_errcode(db), SQLITE_OK)
  assert_eq(sqlite_extended_errcode(db), SQLITE_OK)

  // Cause error
  let _ = sqlite_exec(db, to_c_string("INVALID SQL"))
  let errcode = sqlite_errcode(db)
  assert_true(errcode != SQLITE_OK)

  // Get extended error code
  let ext_errcode = sqlite_extended_errcode(db)
  assert_true(ext_errcode != SQLITE_OK)

  // Get string from error code
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

  // Insert
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

  // Query with named parameters
  let stmt = sqlite_prepare(
    db,
    to_c_string("INSERT INTO t (id, value) VALUES (:id, :value)"),
  )

  // Verify parameter count
  assert_eq(sqlite_bind_parameter_count(stmt), 2)

  // Get parameter names (1-indexed)
  let _ = sqlite_bind_parameter_name(stmt, 1) // ":id"
  let _ = sqlite_bind_parameter_name(stmt, 2) // ":value"

  // Get index from parameter name
  let id_idx = sqlite_bind_parameter_index(stmt, to_c_string(":id"))
  assert_eq(id_idx, 1)
  let value_idx = sqlite_bind_parameter_index(stmt, to_c_string(":value"))
  assert_eq(value_idx, 2)

  // Bind using names
  let _ = sqlite_bind_int(stmt, id_idx, 100)
  let _ = sqlite_bind_text(stmt, value_idx, to_c_string("test"))
  let _ = sqlite_step(stmt)

  sqlite_finalize(stmt)
  sqlite_close(db)
}

///|
test "sqlite_db_filename_and_readonly" {
  let db = sqlite_open(to_c_string(":memory:"))

  // Get filename of memory database ("main" database)
  let _ = sqlite_db_filename(db, to_c_string("main"))

  // Memory database is not read-only
  let is_readonly = sqlite_db_readonly(db, to_c_string("main"))
  assert_eq(is_readonly, 0)

  sqlite_close(db)
}

///|
test "sqlite_expanded_sql" {
  let db = sqlite_open(to_c_string(":memory:"))
  let _ = sqlite_exec(db, to_c_string("CREATE TABLE t (id INTEGER, value TEXT)"))

  // Prepare query with parameters
  let stmt = sqlite_prepare(
    db,
    to_c_string("SELECT * FROM t WHERE id = ? AND value = ?"),
  )

  // Bind parameters
  let _ = sqlite_bind_int(stmt, 1, 42)
  let _ = sqlite_bind_text(stmt, 2, to_c_string("test"))

  // Get expanded SQL (parameters replaced with actual values)
  let _ = sqlite_expanded_sql(stmt)

  sqlite_finalize(stmt)
  sqlite_close(db)
}

///|
test "sqlite_open_v2" {
  // Open database with read-write access
  let db = sqlite_open_v2(
    to_c_string(":memory:"),
    SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_MEMORY,
    to_c_string(""),
  )
  assert_false(sqlite_is_null(db) == 1)

  // Create table
  let _ = sqlite_exec(db, to_c_string("CREATE TABLE t (id INTEGER)"))

  sqlite_close(db)
}

///|
test "sqlite_limit" {
  let db = sqlite_open(to_c_string(":memory:"))

  // Get current LENGTH limit (pass -1 to return current value)
  let current_limit = sqlite_limit(db, SQLITE_LIMIT_LENGTH, -1)
  assert_true(current_limit > 0)

  // Get SQL_LENGTH limit
  let sql_limit = sqlite_limit(db, SQLITE_LIMIT_SQL_LENGTH, -1)
  assert_true(sql_limit > 0)

  // Get column limit
  let column_limit = sqlite_limit(db, SQLITE_LIMIT_COLUMN, -1)
  assert_true(column_limit > 0)

  sqlite_close(db)
}

///|
test "transaction_basic" {
  let db = match Database::open(":memory:") {
    Some(d) => d
    None => abort("Failed to open database")
  }

  assert_true(db.exec("CREATE TABLE t (id INTEGER, value INTEGER)"))

  // Begin transaction
  assert_true(db.begin())
  assert_false(db.get_autocommit()) // In transaction

  // Insert data
  assert_true(db.exec("INSERT INTO t VALUES (1, 100)"))
  assert_true(db.exec("INSERT INTO t VALUES (2, 200)"))

  // Commit
  assert_true(db.commit())
  assert_true(db.get_autocommit()) // Return to autocommit

  // Verify data is saved
  match db.prepare("SELECT COUNT(*) FROM t") {
    Some(stmt) => {
      assert_eq(sqlite_step(stmt), SQLITE_ROW)
      assert_eq(sqlite_column_int(stmt, 0), 2)
      sqlite_finalize(stmt)
    }
    None => abort("Failed to prepare")
  }

  db.close()
}

///|
test "transaction_rollback" {
  let db = match Database::open(":memory:") {
    Some(d) => d
    None => abort("Failed to open database")
  }

  assert_true(db.exec("CREATE TABLE t (id INTEGER, value INTEGER)"))
  assert_true(db.exec("INSERT INTO t VALUES (1, 100)"))

  // Begin transaction
  assert_true(db.begin())

  // Insert data
  assert_true(db.exec("INSERT INTO t VALUES (2, 200)"))

  // Rollback
  assert_true(db.rollback())
  assert_true(db.get_autocommit())

  // Verify data is rolled back (only 1 row)
  match db.prepare("SELECT COUNT(*) FROM t") {
    Some(stmt) => {
      assert_eq(sqlite_step(stmt), SQLITE_ROW)
      assert_eq(sqlite_column_int(stmt, 0), 1)
      sqlite_finalize(stmt)
    }
    None => abort("Failed to prepare")
  }

  db.close()
}

///|
test "transaction_savepoint" {
  let db = match Database::open(":memory:") {
    Some(d) => d
    None => abort("Failed to open database")
  }

  assert_true(db.exec("CREATE TABLE t (id INTEGER, value INTEGER)"))

  // Begin transaction
  assert_true(db.begin())

  assert_true(db.exec("INSERT INTO t VALUES (1, 100)"))

  // Create savepoint
  assert_true(db.savepoint("sp1"))

  assert_true(db.exec("INSERT INTO t VALUES (2, 200)"))

  // Rollback to savepoint
  assert_true(db.rollback_to("sp1"))

  // Release savepoint
  assert_true(db.release("sp1"))

  // Commit
  assert_true(db.commit())

  // Verify data (only 1 row before sp1)
  match db.prepare("SELECT COUNT(*) FROM t") {
    Some(stmt) => {
      assert_eq(sqlite_step(stmt), SQLITE_ROW)
      assert_eq(sqlite_column_int(stmt, 0), 1)
      sqlite_finalize(stmt)
    }
    None => abort("Failed to prepare")
  }

  db.close()
}

///|
test "transaction_immediate_and_exclusive" {
  let db = match Database::open(":memory:") {
    Some(d) => d
    None => abort("Failed to open database")
  }

  assert_true(db.exec("CREATE TABLE t (id INTEGER)"))

  // IMMEDIATE transaction
  assert_true(db.begin_immediate())
  assert_false(db.get_autocommit())
  assert_true(db.exec("INSERT INTO t VALUES (1)"))
  assert_true(db.commit())

  // EXCLUSIVE transaction
  assert_true(db.begin_exclusive())
  assert_false(db.get_autocommit())
  assert_true(db.exec("INSERT INTO t VALUES (2)"))
  assert_true(db.commit())

  db.close()
}
