{
  description = "mizchi/sqlite — libsqlite3 bindings for MoonBit";

  # MoonBit toolchain is intentionally NOT managed by this flake. The overlay
  # lags behind the latest `moon` release enough that its bundled core cannot
  # parse the `moon.pkg` files produced by the current host toolchain, so we
  # let the user install moonbit through the official installer and only
  # provide the surrounding native dependencies here.
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        apm = import ./apm.nix { inherit pkgs; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            # Native deps: stub.c links `-lsqlite3` and includes <sqlite3.h>.
            pkgs.sqlite
            pkgs.pkg-config

            # Common tooling
            pkgs.git # apm's GitHub downloader shells out to `git version`
            pkgs.just
            pkgs.ast-grep
            apm
          ];

          shellHook = ''
            if ! command -v moon >/dev/null 2>&1; then
              echo "[warning] moon not found on PATH — install via https://www.moonbitlang.com/download" >&2
            fi
          '';
        };
      });
}
