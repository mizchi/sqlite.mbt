// Deno SQLite Benchmark using node:sqlite
// Run with: deno bench --allow-read --allow-write --allow-ffi sqlite_bench.ts

import { DatabaseSync } from "node:sqlite";

const ITERATIONS = 1000;

// Setup database
function setupDatabase(): DatabaseSync {
  const db = new DatabaseSync(":memory:");
  db.exec(`
    CREATE TABLE users (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      age INTEGER NOT NULL
    )
  `);
  return db;
}

Deno.bench("SQLite: Database Open/Close", () => {
  const db = new DatabaseSync(":memory:");
  db.close();
});

Deno.bench("SQLite: Create Table", () => {
  const db = new DatabaseSync(":memory:");
  db.exec(`
    CREATE TABLE users (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      age INTEGER NOT NULL
    )
  `);
  db.close();
});

Deno.bench("SQLite: Insert Single Row", () => {
  const db = setupDatabase();
  const stmt = db.prepare("INSERT INTO users (name, age) VALUES (?, ?)");
  stmt.run("Alice", 30);
  db.close();
});

Deno.bench("SQLite: Insert 100 Rows", () => {
  const db = setupDatabase();
  const stmt = db.prepare("INSERT INTO users (name, age) VALUES (?, ?)");
  for (let i = 0; i < 100; i++) {
    stmt.run(`User${i}`, 20 + (i % 50));
  }
  db.close();
});

Deno.bench("SQLite: Insert with Transaction (100 rows)", () => {
  const db = setupDatabase();
  db.exec("BEGIN TRANSACTION");
  const stmt = db.prepare("INSERT INTO users (name, age) VALUES (?, ?)");
  for (let i = 0; i < 100; i++) {
    stmt.run(`User${i}`, 20 + (i % 50));
  }
  db.exec("COMMIT");
  db.close();
});

Deno.bench("SQLite: Select All Rows", () => {
  const db = setupDatabase();
  const insertStmt = db.prepare("INSERT INTO users (name, age) VALUES (?, ?)");
  for (let i = 0; i < 100; i++) {
    insertStmt.run(`User${i}`, 20 + (i % 50));
  }

  const selectStmt = db.prepare("SELECT * FROM users");
  const rows = selectStmt.all();
  db.close();
});

Deno.bench("SQLite: Select with WHERE clause", () => {
  const db = setupDatabase();
  const insertStmt = db.prepare("INSERT INTO users (name, age) VALUES (?, ?)");
  for (let i = 0; i < 100; i++) {
    insertStmt.run(`User${i}`, 20 + (i % 50));
  }

  const selectStmt = db.prepare("SELECT * FROM users WHERE age > ?");
  const rows = selectStmt.all(30);
  db.close();
});

Deno.bench("SQLite: Update Rows", () => {
  const db = setupDatabase();
  const insertStmt = db.prepare("INSERT INTO users (name, age) VALUES (?, ?)");
  for (let i = 0; i < 100; i++) {
    insertStmt.run(`User${i}`, 20 + (i % 50));
  }

  const updateStmt = db.prepare("UPDATE users SET age = ? WHERE age > ?");
  updateStmt.run(25, 30);
  db.close();
});

Deno.bench("SQLite: Delete Rows", () => {
  const db = setupDatabase();
  const insertStmt = db.prepare("INSERT INTO users (name, age) VALUES (?, ?)");
  for (let i = 0; i < 100; i++) {
    insertStmt.run(`User${i}`, 20 + (i % 50));
  }

  const deleteStmt = db.prepare("DELETE FROM users WHERE age > ?");
  deleteStmt.run(40);
  db.close();
});

Deno.bench("SQLite: Prepared Statement Reuse", () => {
  const db = setupDatabase();
  const stmt = db.prepare("INSERT INTO users (name, age) VALUES (?, ?)");
  for (let i = 0; i < 50; i++) {
    stmt.run(`User${i}`, 20 + i);
  }
  db.close();
});
