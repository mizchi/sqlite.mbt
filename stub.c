#include <sqlite3.h>
#include <moonbit.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

// MoonBitのBytesからC文字列を取得するヘルパー
// @encoding.encode_utf8()はUTF-8エンコーディングなので、そのままコピーしてNULL終端を追加
static char* bytes_to_cstring(moonbit_bytes_t bytes) {
    int32_t len = Moonbit_array_length(bytes);
    char* str = (char*)malloc(len + 1);
    memcpy(str, bytes, len);
    str[len] = '\0';
    return str;
}

// データベースを開く（成功時はdb, 失敗時はNULL）
sqlite3* sqlite_open(moonbit_bytes_t filename) {
    char* fname = bytes_to_cstring(filename);
    sqlite3* db;
    int rc = sqlite3_open(fname, &db);
    free(fname);
    if (rc != SQLITE_OK) {
        sqlite3_close(db);
        return NULL;
    }
    return db;
}

// ポインタがNULLかどうかをチェック
int32_t sqlite_is_null(void* ptr) {
    return ptr == NULL ? 1 : 0;
}

int32_t sqlite_stmt_is_null(sqlite3_stmt* ptr) {
    return ptr == NULL ? 1 : 0;
}

// データベースを閉じる
void sqlite_close(sqlite3* db) {
    sqlite3_close(db);
}

// SQL実行（結果なし）。0=成功
int32_t sqlite_exec(sqlite3* db, moonbit_bytes_t sql) {
    char* sql_str = bytes_to_cstring(sql);
    char* err_msg = NULL;
    int rc = sqlite3_exec(db, sql_str, NULL, NULL, &err_msg);
    free(sql_str);
    if (err_msg) {
        sqlite3_free(err_msg);
    }
    return rc;
}

// プリペアドステートメントを作成（失敗時はNULL）
sqlite3_stmt* sqlite_prepare(sqlite3* db, moonbit_bytes_t sql) {
    char* sql_str = bytes_to_cstring(sql);
    sqlite3_stmt* stmt = NULL;
    int rc = sqlite3_prepare_v2(db, sql_str, -1, &stmt, NULL);
    free(sql_str);
    if (rc != SQLITE_OK) {
        return NULL;
    }
    return stmt;
}

// ステートメントを破棄
void sqlite_finalize(sqlite3_stmt* stmt) {
    sqlite3_finalize(stmt);
}

// パラメータをバインド（1-indexed）
int32_t sqlite_bind_int(sqlite3_stmt* stmt, int32_t idx, int32_t value) {
    return sqlite3_bind_int(stmt, idx, value);
}

int32_t sqlite_bind_double(sqlite3_stmt* stmt, int32_t idx, double value) {
    return sqlite3_bind_double(stmt, idx, value);
}

int32_t sqlite_bind_text(sqlite3_stmt* stmt, int32_t idx, moonbit_bytes_t text) {
    char* text_str = bytes_to_cstring(text);
    int rc = sqlite3_bind_text(stmt, idx, text_str, -1, SQLITE_TRANSIENT);
    free(text_str);
    return rc;
}

// 次の行に進む。100=SQLITE_ROW(データあり), 101=SQLITE_DONE(終了)
int32_t sqlite_step(sqlite3_stmt* stmt) {
    return sqlite3_step(stmt);
}

// カラムの値を取得（0-indexed）
int32_t sqlite_column_int(sqlite3_stmt* stmt, int32_t col) {
    return sqlite3_column_int(stmt, col);
}

double sqlite_column_double(sqlite3_stmt* stmt, int32_t col) {
    return sqlite3_column_double(stmt, col);
}

const char* sqlite_column_text(sqlite3_stmt* stmt, int32_t col) {
    return (const char*)sqlite3_column_text(stmt, col);
}

// ステートメントをリセット（再利用可能に）
void sqlite_reset(sqlite3_stmt* stmt) {
    sqlite3_reset(stmt);
}

// エラーハンドリング
int32_t sqlite_errcode(sqlite3* db) {
    return sqlite3_errcode(db);
}

const char* sqlite_errmsg(sqlite3* db) {
    return sqlite3_errmsg(db);
}

// 追加のバインド関数
int32_t sqlite_bind_null(sqlite3_stmt* stmt, int32_t idx) {
    return sqlite3_bind_null(stmt, idx);
}

int32_t sqlite_bind_int64(sqlite3_stmt* stmt, int32_t idx, int64_t value) {
    return sqlite3_bind_int64(stmt, idx, value);
}

int32_t sqlite_bind_blob(sqlite3_stmt* stmt, int32_t idx, moonbit_bytes_t blob) {
    int32_t len = Moonbit_array_length(blob);
    return sqlite3_bind_blob(stmt, idx, blob, len, SQLITE_TRANSIENT);
}

// 追加のカラム取得関数
int64_t sqlite_column_int64(sqlite3_stmt* stmt, int32_t col) {
    return sqlite3_column_int64(stmt, col);
}

const void* sqlite_column_blob(sqlite3_stmt* stmt, int32_t col) {
    return sqlite3_column_blob(stmt, col);
}

int32_t sqlite_column_bytes(sqlite3_stmt* stmt, int32_t col) {
    return sqlite3_column_bytes(stmt, col);
}

int32_t sqlite_column_type(sqlite3_stmt* stmt, int32_t col) {
    return sqlite3_column_type(stmt, col);
}

// メタデータ関数
int32_t sqlite_column_count(sqlite3_stmt* stmt) {
    return sqlite3_column_count(stmt);
}

const char* sqlite_column_name(sqlite3_stmt* stmt, int32_t col) {
    return sqlite3_column_name(stmt, col);
}

int32_t sqlite_changes(sqlite3* db) {
    return sqlite3_changes(db);
}

int64_t sqlite_last_insert_rowid(sqlite3* db) {
    return sqlite3_last_insert_rowid(db);
}

// ステートメントクリア
int32_t sqlite_clear_bindings(sqlite3_stmt* stmt) {
    return sqlite3_clear_bindings(stmt);
}

// 並行アクセス制御
int32_t sqlite_busy_timeout(sqlite3* db, int32_t ms) {
    return sqlite3_busy_timeout(db, ms);
}

// トランザクション管理
int32_t sqlite_get_autocommit(sqlite3* db) {
    return sqlite3_get_autocommit(db);
}

int32_t sqlite_total_changes(sqlite3* db) {
    return sqlite3_total_changes(db);
}

// ステートメント Introspection
const char* sqlite_sql(sqlite3_stmt* stmt) {
    const char* sql = sqlite3_sql(stmt);
    return sql ? sql : "";
}

int32_t sqlite_bind_parameter_count(sqlite3_stmt* stmt) {
    return sqlite3_bind_parameter_count(stmt);
}

int32_t sqlite_stmt_readonly(sqlite3_stmt* stmt) {
    return sqlite3_stmt_readonly(stmt);
}

// 拡張エラー処理
int32_t sqlite_extended_errcode(sqlite3* db) {
    return sqlite3_extended_errcode(db);
}

// グローバルバッファ（静的領域）にエラー文字列をコピー
// 注: sqlite3_errstr は静的文字列を返すので、それをコピーする
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

// パラメータ名を取得（静的文字列をバッファにコピー）
static char param_name_buffer[256];

const char* sqlite_bind_parameter_name(sqlite3_stmt* stmt, int32_t idx) {
    const char* name = sqlite3_bind_parameter_name(stmt, idx);
    if (name) {
        strncpy(param_name_buffer, name, sizeof(param_name_buffer) - 1);
        param_name_buffer[sizeof(param_name_buffer) - 1] = '\0';
        return param_name_buffer;
    }
    return "";
}

int32_t sqlite_bind_parameter_index(sqlite3_stmt* stmt, moonbit_bytes_t name) {
    char* name_str = bytes_to_cstring(name);
    int idx = sqlite3_bind_parameter_index(stmt, name_str);
    free(name_str);
    return idx;
}
