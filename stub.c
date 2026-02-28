#include <moonbit.h>
#include <sqlite3.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void noop_finalizer(void* self) {}

// Helper functions to wrap raw sqlite3* and sqlite3_stmt* pointers in MoonBit external objects

static void* wrap_db(sqlite3* db) {
    if (!db) return NULL;
    void* obj = moonbit_make_external_object(noop_finalizer, sizeof(sqlite3*));
    *(sqlite3**)obj = db;
    return obj;
}

static void* wrap_stmt(sqlite3_stmt* stmt) {
    if (!stmt) return NULL;
    void* obj = moonbit_make_external_object(noop_finalizer, sizeof(sqlite3_stmt*));
    *(sqlite3_stmt**)obj = stmt;
    return obj;
}

static inline sqlite3* get_db(void* obj) {
    if (!obj) return NULL;
    return *(sqlite3**)obj;
}

static inline sqlite3_stmt* get_stmt(void* obj) {
    if (!obj) return NULL;
    return *(sqlite3_stmt**)obj;
}

// Helper to convert MoonBit Bytes to C string
// @encoding.encode_utf8() returns UTF-8 encoded bytes, so we copy directly and add NULL terminator
static char* bytes_to_cstring(moonbit_bytes_t bytes) {
    int32_t len = Moonbit_array_length(bytes);
    char* str = (char*)malloc(len + 1);
    memcpy(str, bytes, len);
    str[len] = '\0';
    return str;
}

// Open database (returns db on success, NULL on failure)
void* sqlite_open(moonbit_bytes_t filename) {
    char* fname = bytes_to_cstring(filename);
    sqlite3* db;
    int rc = sqlite3_open(fname, &db);
    free(fname);
    if (rc != SQLITE_OK) {
        sqlite3_close(db);
        return NULL;
    }
    return wrap_db(db);
}

// Open database with extended options
void* sqlite_open_v2(moonbit_bytes_t filename, int32_t flags, moonbit_bytes_t vfs) {
    char* fname = bytes_to_cstring(filename);
    char* vfs_str = NULL;
    if (Moonbit_array_length(vfs) > 0) {
        vfs_str = bytes_to_cstring(vfs);
    }

    sqlite3* db;
    int rc = sqlite3_open_v2(fname, &db, flags, vfs_str);

    free(fname);
    if (vfs_str) free(vfs_str);

    if (rc != SQLITE_OK) {
        sqlite3_close(db);
        return NULL;
    }
    return wrap_db(db);
}

// Check if pointer is NULL
int32_t sqlite_is_null(void* ptr) {
    return ptr == NULL ? 1 : 0;
}

int32_t sqlite_stmt_is_null(void* ptr) {
    return ptr == NULL ? 1 : 0;
}

// Close database
void sqlite_close(void* obj) { sqlite3_close(get_db(obj)); }

// Execute SQL (no result). Returns 0 on success
int32_t sqlite_exec(void* obj, moonbit_bytes_t sql) {
    char* sql_str = bytes_to_cstring(sql);
    char* err_msg = NULL;
    int rc = sqlite3_exec(get_db(obj), sql_str, NULL, NULL, &err_msg);
    free(sql_str);
    if (err_msg) {
        sqlite3_free(err_msg);
    }
    return rc;
}

// Create prepared statement (returns NULL on failure)
void* sqlite_prepare(void* obj, moonbit_bytes_t sql) {
    char* sql_str = bytes_to_cstring(sql);
    sqlite3_stmt* stmt = NULL;
    int rc = sqlite3_prepare_v2(get_db(obj), sql_str, -1, &stmt, NULL);
    free(sql_str);
    if (rc != SQLITE_OK) {
        return NULL;
    }
    return wrap_stmt(stmt);
}

// Finalize statement
void sqlite_finalize(void* obj) { sqlite3_finalize(get_stmt(obj)); }

// Bind parameter (1-indexed)
int32_t sqlite_bind_int(void* obj, int32_t idx, int32_t value) {
    return sqlite3_bind_int(get_stmt(obj), idx, value);
}

int32_t sqlite_bind_double(void* obj, int32_t idx, double value) {
    return sqlite3_bind_double(get_stmt(obj), idx, value);
}

int32_t sqlite_bind_text(void* obj, int32_t idx, moonbit_bytes_t text) {
    char* text_str = bytes_to_cstring(text);
    int rc = sqlite3_bind_text(get_stmt(obj), idx, text_str, -1, SQLITE_TRANSIENT);
    free(text_str);
    return rc;
}

// Step to next row. 100=SQLITE_ROW (has data), 101=SQLITE_DONE (finished)
int32_t sqlite_step(void* obj) { return sqlite3_step(get_stmt(obj)); }

// Get column value (0-indexed)
int32_t sqlite_column_int(void* obj, int32_t col) {
    return sqlite3_column_int(get_stmt(obj), col);
}

double sqlite_column_double(void* obj, int32_t col) {
    return sqlite3_column_double(get_stmt(obj), col);
}

// Return SQLite text column as MoonBit Bytes
// moonbit_bytes_t is a length-prefixed byte array
moonbit_bytes_t sqlite_column_text(void* obj, int32_t col) {
    sqlite3_stmt* stmt = get_stmt(obj);
    const unsigned char* text = sqlite3_column_text(stmt, col);
    int len = sqlite3_column_bytes(stmt, col);
    if (text == NULL || len == 0) {
        return moonbit_make_bytes(0, 0);
    }
    moonbit_bytes_t result = moonbit_make_bytes(len, 0);
    memcpy(result, text, len);
    return result;
}

// Reset statement (make it reusable)
void sqlite_reset(void* obj) { sqlite3_reset(get_stmt(obj)); }

// Error handling
int32_t sqlite_errcode(void* obj) { return sqlite3_errcode(get_db(obj)); }

const char* sqlite_errmsg(void* obj) { return sqlite3_errmsg(get_db(obj)); }

// Additional bind functions
int32_t sqlite_bind_null(void* obj, int32_t idx) {
    return sqlite3_bind_null(get_stmt(obj), idx);
}

// Note: Using int64_t for idx to avoid ABI issues with mixed 32/64-bit parameters
// on some platforms (Linux x86-64). MoonBit may pass parameters differently
// when mixing Int and Int64 types.
int32_t sqlite_bind_int64(void* obj, int64_t idx, int64_t value) {
    return sqlite3_bind_int64(get_stmt(obj), (int)idx, value);
}

int32_t sqlite_bind_blob(void* obj, int32_t idx, moonbit_bytes_t blob) {
    int32_t len = Moonbit_array_length(blob);
    return sqlite3_bind_blob(get_stmt(obj), idx, blob, len, SQLITE_TRANSIENT);
}

// Additional column getter functions
int64_t sqlite_column_int64(void* obj, int32_t col) {
    return sqlite3_column_int64(get_stmt(obj), col);
}

// Return SQLite BLOB column as MoonBit Bytes
moonbit_bytes_t sqlite_column_blob(void* obj, int32_t col) {
    sqlite3_stmt* stmt = get_stmt(obj);
    const void* blob = sqlite3_column_blob(stmt, col);
    int len = sqlite3_column_bytes(stmt, col);
    if (blob == NULL || len == 0) {
        return moonbit_make_bytes(0, 0);
    }
    moonbit_bytes_t result = moonbit_make_bytes(len, 0);
    memcpy(result, blob, len);
    return result;
}

int32_t sqlite_column_bytes(void* obj, int32_t col) {
    return sqlite3_column_bytes(get_stmt(obj), col);
}

int32_t sqlite_column_type(void* obj, int32_t col) {
    return sqlite3_column_type(get_stmt(obj), col);
}

// Metadata functions
int32_t sqlite_column_count(void* obj) {
    return sqlite3_column_count(get_stmt(obj));
}

const char* sqlite_column_name(void* obj, int32_t col) {
    return sqlite3_column_name(get_stmt(obj), col);
}

int32_t sqlite_changes(void* obj) { return sqlite3_changes(get_db(obj)); }

int64_t sqlite_last_insert_rowid(void* obj) {
    return sqlite3_last_insert_rowid(get_db(obj));
}

// Clear statement bindings
int32_t sqlite_clear_bindings(void* obj) {
    return sqlite3_clear_bindings(get_stmt(obj));
}

// Concurrency control
int32_t sqlite_busy_timeout(void* obj, int32_t ms) {
    return sqlite3_busy_timeout(get_db(obj), ms);
}

// Transaction management
int32_t sqlite_get_autocommit(void* obj) {
    return sqlite3_get_autocommit(get_db(obj));
}

int32_t sqlite_total_changes(void* obj) {
    return sqlite3_total_changes(get_db(obj));
}

// Statement introspection
const char* sqlite_sql(void* obj) {
    const char* sql = sqlite3_sql(get_stmt(obj));
    return sql ? sql : "";
}

int32_t sqlite_bind_parameter_count(void* obj) {
    return sqlite3_bind_parameter_count(get_stmt(obj));
}

int32_t sqlite_stmt_readonly(void* obj) {
    return sqlite3_stmt_readonly(get_stmt(obj));
}

// Extended error handling
int32_t sqlite_extended_errcode(void* obj) {
    return sqlite3_extended_errcode(get_db(obj));
}

// Copy error string to global buffer (static storage)
// Note: sqlite3_errstr returns static string, so we copy it
static char errstr_buffer[256];

const char* sqlite_errstr(int32_t errcode) {
    const char* msg = sqlite3_errstr(errcode);
    if (msg) {
        strncpy(errstr_buffer, msg, sizeof(errstr_buffer) - 1);
        errstr_buffer[sizeof(errstr_buffer) - 1] = '\0';
        return errstr_buffer;
    }
    return "";
}

// Get parameter name (copy static string to buffer)
static char param_name_buffer[256];

const char* sqlite_bind_parameter_name(void* obj, int32_t idx) {
    const char* name = sqlite3_bind_parameter_name(get_stmt(obj), idx);
    if (name) {
        strncpy(param_name_buffer, name, sizeof(param_name_buffer) - 1);
        param_name_buffer[sizeof(param_name_buffer) - 1] = '\0';
        return param_name_buffer;
    }
    return "";
}

int32_t sqlite_bind_parameter_index(void* obj, moonbit_bytes_t name) {
    char* name_str = bytes_to_cstring(name);
    int idx = sqlite3_bind_parameter_index(get_stmt(obj), name_str);
    free(name_str);
    return idx;
}

// Get database filename (copy static string to buffer)
static char db_filename_buffer[512];

const char* sqlite_db_filename(void* obj, moonbit_bytes_t dbname) {
    char* dbname_str = bytes_to_cstring(dbname);
    const char* filename = sqlite3_db_filename(get_db(obj), dbname_str);
    free(dbname_str);

    if (filename) {
        strncpy(db_filename_buffer, filename, sizeof(db_filename_buffer) - 1);
        db_filename_buffer[sizeof(db_filename_buffer) - 1] = '\0';
        return db_filename_buffer;
    }
    return "";
}

int32_t sqlite_db_readonly(void* obj, moonbit_bytes_t dbname) {
    char* dbname_str = bytes_to_cstring(dbname);
    int readonly = sqlite3_db_readonly(get_db(obj), dbname_str);
    free(dbname_str);
    return readonly;
}

// Get expanded SQL (dynamically allocated string)
static char expanded_sql_buffer[1024];

const char* sqlite_expanded_sql(void* obj) {
    char* sql = sqlite3_expanded_sql(get_stmt(obj));
    if (sql) {
        strncpy(expanded_sql_buffer, sql, sizeof(expanded_sql_buffer) - 1);
        expanded_sql_buffer[sizeof(expanded_sql_buffer) - 1] = '\0';
        sqlite3_free(sql); // Important: free dynamically allocated string
        return expanded_sql_buffer;
    }
    return "";
}

// Interrupt running query
void sqlite_interrupt(void* obj) {
    sqlite3_interrupt(get_db(obj));
}

// Set/get resource limits
int32_t sqlite_limit(void* obj, int32_t id, int32_t newVal) {
    return sqlite3_limit(get_db(obj), id, newVal);
}
