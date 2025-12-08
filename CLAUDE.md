# Project CLAUDE.md Guide

This is a [MoonBit](https://docs.moonbitlang.com) project.

## Native Target

This project targets **native** (not wasm-gc). All build and test commands must include `--target native`.

### C FFI (Foreign Function Interface)

This project uses C language bindings via MoonBit's C-FFI feature.

**Key files:**
- `cwrap.c` - C wrapper functions that MoonBit calls via `extern "C"`
- `moon.pkg.json` - Contains `"native-stub": ["cwrap.c"]` to include C source

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

