# Project CLAUDE.md Guide

This is a [MoonBit](https://docs.moonbitlang.com) project.

## Native Target

This project targets **native** (not wasm-gc). All build and test commands must include `--target native`.

### C FFI (Foreign Function Interface)

This project uses C language bindings via MoonBit's C-FFI feature.

**Key files:**
- `stub.c` - C wrapper functions that MoonBit calls via `extern "C"`
- `moon.pkg.json` - Contains `"native-stub": ["stub.c"]` to include C source

**How it works:**
1. MoonBit declares external C functions: `extern "C" fn name(args) -> Type = "c_func_name"`
2. C implementations are provided in `cwrap.c`
3. `moon build --target native` compiles MoonBit to C, then links with `cwrap.c`

**Commands:**
```bash
moon build --target native   # Build executable
moon run . --target native   # Run the program
moon test --target native    # Run tests
```

**Type mapping (MoonBit → C):**
- `Int` → `int32_t`
- `Int64` → `int64_t`
- `Double` → `double`
- `Bool` → `int32_t` (0/1)
- `Unit` → `void`

## Project Structure

- MoonBit packages are organized per directory, for each directory, there is a
  `moon.pkg.json` file listing its dependencies. Each package has its files and
  blackbox test files (common, ending in `_test.mbt`) and whitebox test files
  (ending in `_wbtest.mbt`).

- In the toplevel directory, this is a `moon.mod.json` file listing about the
  module and some meta information.

## Coding convention

- MoonBit code is organized in block style, each block is separated by `///|`,
  the order of each block is irrelevant. In some refactorings, you can process
  block by block independently.

- Try to keep deprecated blocks in file called `deprecated.mbt` in each
  directory.

## Tooling

- `moon fmt` is used to format your code properly.

- `moon info` is used to update the generated interface of the package, each
  package has a generated interface file `.mbti`, it is a brief formal
  description of the package. If nothing in `.mbti` changes, this means your
  change does not bring the visible changes to the external package users, it is
  typically a safe refactoring.

- In the last step, run `moon info && moon fmt` to update the interface and
  format the code. Check the diffs of `.mbti` file to see if the changes are
  expected.

- Run `moon test` to check the test is passed. MoonBit supports snapshot
  testing, so when your changes indeed change the behavior of the code, you
  should run `moon test --update` to update the snapshot.

- You can run `moon check` to check the code is linted correctly.

- When writing tests, you are encouraged to use `inspect` and run
  `moon test --update` to update the snapshots, only use assertions like
  `assert_eq` when you are in some loops where each snapshot may vary. You can
  use `moon coverage analyze > uncovered.log` to see which parts of your code
  are not covered by tests.

- CLAUDE.md has some small tasks that are easy for AI to pick up, agent is
  welcome to finish the tasks and check the box when you are done


## Resolved Issues

### Priority 2 Features - SOLVED ✅

以下の機能は当初SIGBUS/無限ループの問題があったが、解決済み：

1. **`sqlite3_extended_errcode` + `sqlite3_errstr`** ✅
   - 問題: SIGBUS エラー
   - 原因: SQLiteが返す静的文字列ポインタをMoonBitの`Bytes`型に直接変換しようとすると、メモリアクセス違反が発生
   - 解決策: 静的文字列をグローバルバッファ（`static char errstr_buffer[256]`）にコピーしてから返す

2. **`sqlite3_bind_parameter_name` + `sqlite3_bind_parameter_index`** ✅
   - 問題: 無限ループまたはハング
   - 原因: 同じく静的文字列の直接変換による問題
   - 解決策: 静的文字列をグローバルバッファ（`static char param_name_buffer[256]`）にコピーしてから返す

### 学習した知見

**MoonBit C FFI での文字列処理のベストプラクティス:**

1. **動的に生成される文字列（データベースハンドル/ステートメントに紐づく）**
   - `sqlite3_column_text`, `sqlite3_errmsg`など
   - 直接`const char*`を返しても問題なし（MoonBitが適切に処理）

2. **静的文字列（グローバルな定数文字列）**
   - `sqlite3_errstr`, `sqlite3_bind_parameter_name`など
   - **必ずバッファにコピーしてから返す必要がある**
   - 例: `strncpy(buffer, src, size); return buffer;`

3. **NULL処理**
   - NULL の可能性がある場合は空文字列`""`を返す
   - 例: `return name ? name : "";`

