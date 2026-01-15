// SQLite bindings for MoonBit (Node.js backend via node:sqlite)

// Common types

///|
pub(all) enum SqlValue {
  Null
  Int(Int)
  Int64(Int64)
  Double(Double)
  Text(Bytes)
  Blob(Bytes)
}

// Helper functions

///|
fn string_to_bytes(s : String) -> Bytes {
  let encoded = @js_encoding.TextEncoder::new().encode(s)
  @jscore.identity(encoded)
}

///|
fn bytes_to_string(b : Bytes) -> String {
  @js_encoding.TextDecoder::new().decode(@jscore.identity(b))
}

///|
fn empty_bytes() -> Bytes {
  string_to_bytes("")
}

///|
extern "js" fn is_integer(v : @jscore.Any) -> Bool =
  #| (v) => Number.isInteger(v)

///|
extern "js" fn bigint_to_number(v : @jscore.Any) -> Int =
  #| (v) => Number(v)

///|
fn is_uint8array(v : @jscore.Any) -> Bool {
  let ctor = @jscore.global_this()._get("Uint8Array")
  @jscore.instanceof_(v, ctor)
}

///|
fn sql_value_to_any(value : SqlValue) -> @jscore.Any {
  match value {
    Null => @jscore.null()
    Int(v) => @jscore.any(v)
    Int64(v) => @jscore.any(v)
    Double(v) => @jscore.any(v)
    Text(v) => @jscore.any(bytes_to_string(v))
    Blob(v) => @jscore.any(v)
  }
}

///|
fn any_to_sql_value(value : @jscore.Any) -> SqlValue {
  if @jscore.is_nullish(value) {
    Null
  } else {
    let kind = @jscore.typeof_(value)
    if kind == "number" {
      if is_integer(value) {
        Int(value.cast())
      } else {
        Double(value.cast())
      }
    } else if kind == "bigint" {
      Int64(value.cast())
    } else if kind == "string" {
      Text(string_to_bytes(value.cast()))
    } else if is_uint8array(value) {
      Blob(value.cast())
    } else {
      Null
    }
  }
}

///|
fn any_to_bytes(value : @jscore.Any) -> Bytes {
  if @jscore.is_nullish(value) {
    empty_bytes()
  } else {
    let kind = @jscore.typeof_(value)
    if kind == "string" {
      string_to_bytes(value.cast())
    } else if is_uint8array(value) {
      value.cast()
    } else {
      empty_bytes()
    }
  }
}

///|
priv struct StatementState {
  stmt : @node_sqlite.StatementSync
  mut bound : Array[SqlValue]
  mut rows : Array[@jscore.Any]
  mut row_index : Int
  mut current_row : @jscore.Any?
  mut done : Bool
}

///|
fn statement_state_new(stmt : @node_sqlite.StatementSync) -> StatementState {
  { stmt, bound: [], rows: [], row_index: 0, current_row: None, done: false }
}

///|
fn statement_bound_params(state : StatementState) -> Array[@jscore.Any] {
  let params : Array[@jscore.Any] = []
  for value in state.bound {
    params.push(sql_value_to_any(value))
  }
  params
}

///|
fn statement_reset_state(state : StatementState) -> Unit {
  state.rows = []
  state.row_index = 0
  state.current_row = None
  state.done = false
}

// High-level API

///|
pub struct Database {
  priv db : @node_sqlite.DatabaseSync
}

///|
pub fn Database::open(path : String) -> Database? {
  Some({ db: @node_sqlite.DatabaseSync::new(path, returnArrays=true) })
}

///|
pub fn Database::close(self : Database) -> Unit {
  self.db.close()
}

///|
pub fn Database::exec(self : Database, sql : String) -> Bool {
  self.db.exec(sql)
  true
}

///|
pub fn Database::prepare(self : Database, sql : String) -> Statement? {
  Some({ state: statement_state_new(self.db.prepare(sql)) })
}

///|
pub fn Database::query(self : Database, sql : String) -> Statement? {
  self.prepare(sql)
}

///|
pub fn Database::errcode(self : Database) -> Int {
  let _ = self
  0
}

///|
pub fn Database::errmsg(self : Database) -> Bytes {
  let _ = self
  empty_bytes()
}

///|
pub fn Database::extended_errcode(self : Database) -> Int {
  let _ = self
  0
}

///|
pub fn Database::changes(self : Database) -> Int {
  match self.prepare("SELECT changes()") {
    Some(stmt) => {
      let mut result = 0
      if stmt.step() {
        result = stmt.column_int(0)
      }
      stmt.finalize()
      result
    }
    None => 0
  }
}

///|
pub fn Database::last_insert_rowid(self : Database) -> Int64 {
  match self.prepare("SELECT last_insert_rowid()") {
    Some(stmt) => {
      let mut result : Int64 = 0L
      if stmt.step() {
        result = stmt.column_int(0).to_int64()
      }
      stmt.finalize()
      result
    }
    None => 0L
  }
}

///|
pub fn Database::busy_timeout(self : Database, ms : Int) -> Bool {
  let _ = self
  let _ = ms
  false
}

///|
pub fn Database::get_autocommit(self : Database) -> Bool {
  let _ = self
  true
}

///|
pub fn Database::total_changes(self : Database) -> Int {
  match self.prepare("SELECT total_changes()") {
    Some(stmt) => {
      let mut result = 0
      if stmt.step() {
        result = stmt.column_int(0)
      }
      stmt.finalize()
      result
    }
    None => 0
  }
}

// Transaction API

///|
pub fn Database::begin(self : Database) -> Bool {
  self.exec("BEGIN")
}

///|
pub fn Database::begin_immediate(self : Database) -> Bool {
  self.exec("BEGIN IMMEDIATE")
}

///|
pub fn Database::begin_exclusive(self : Database) -> Bool {
  self.exec("BEGIN EXCLUSIVE")
}

///|
pub fn Database::commit(self : Database) -> Bool {
  self.exec("COMMIT")
}

///|
pub fn Database::rollback(self : Database) -> Bool {
  self.exec("ROLLBACK")
}

///|
pub fn Database::savepoint(self : Database, name : String) -> Bool {
  self.exec("SAVEPOINT " + name)
}

///|
pub fn Database::release(self : Database, name : String) -> Bool {
  self.exec("RELEASE " + name)
}

///|
pub fn Database::rollback_to(self : Database, name : String) -> Bool {
  self.exec("ROLLBACK TO " + name)
}

///|
pub struct Statement {
  priv state : StatementState
}

///|
pub fn Statement::step(self : Statement) -> Bool {
  if self.state.done {
    return false
  }
  if self.state.row_index == 0 && self.state.rows.length() == 0 {
    self.state.rows = self.state.stmt.all(anonymous_parameters=statement_bound_params(self.state))
  }
  if self.state.row_index < self.state.rows.length() {
    let row = self.state.rows[self.state.row_index]
    self.state.row_index = self.state.row_index + 1
    self.state.current_row = Some(row)
    true
  } else {
    self.state.done = true
    self.state.current_row = None
    false
  }
}

///|
pub fn Statement::execute(self : Statement) -> Bool {
  self.state.stmt.run(anonymous_parameters=statement_bound_params(self.state)) |> ignore
  statement_reset_state(self.state)
  true
}

///|
pub fn Statement::column_int(self : Statement, col : Int) -> Int {
  match stmt_column_any(self.state, col) {
    Some(value) => {
      let kind = @jscore.typeof_(value)
      if kind == "number" {
        value.cast()
      } else if kind == "bigint" {
        bigint_to_number(value)
      } else {
        0
      }
    }
    None => 0
  }
}

///|
pub fn Statement::column_text(self : Statement, col : Int) -> Bytes {
  match stmt_column_any(self.state, col) {
    Some(value) => any_to_bytes(value)
    None => empty_bytes()
  }
}

///|
pub fn Statement::column_count(self : Statement) -> Int {
  self.state.stmt.columns().length()
}

///|
pub fn Statement::bind(self : Statement, idx : Int, value : SqlValue) -> Bool {
  if idx <= 0 {
    return false
  }
  let target = idx - 1
  while self.state.bound.length() <= target {
    self.state.bound.push(Null)
  }
  self.state.bound[target] = value
  true
}

///|
pub fn Statement::bind_all(self : Statement, values : Array[SqlValue]) -> Bool {
  self.state.bound = values
  true
}

///|
pub fn Statement::column(self : Statement, col : Int) -> SqlValue {
  match stmt_column_any(self.state, col) {
    Some(value) => any_to_sql_value(value)
    None => Null
  }
}

///|
pub fn Statement::reset(self : Statement) -> Unit {
  statement_reset_state(self.state)
}

///|
pub fn Statement::finalize(self : Statement) -> Unit {
  statement_reset_state(self.state)
}

///|
pub fn Statement::iter(self : Statement) -> Iter[Statement] {
  self.reset()
  Iter::new(fn() { if self.step() { Some(self) } else { None } })
}

///|
fn stmt_column_any(state : StatementState, col : Int) -> @jscore.Any? {
  match state.current_row {
    Some(row) => Some(@jscore.any(row)._get_by_index(col))
    None => None
  }
}
