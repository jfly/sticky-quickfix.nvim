{ pkgs }:
pkgs.termtosvg.override (oldAttrs: {
  python3Packages =
    (pkgs.python3.override {
      packageOverrides = self: super: {
        pyte = super.pyte.overridePythonAttrs (oldAttrs: {

          # https://github.com/NixOS/nixpkgs/pull/347321
          version = "0.8.2-unstable-2024-10-08";
          src = pkgs.fetchFromGitHub {
            owner = "selectel";
            repo = oldAttrs.pname;
            rev = "0.8.2";
            hash = "sha256-u24ltX/LEteiZ2a/ioKqxV2AZgrFmKOHXmySmw21sLE=";
          };

          # Avoid escape code spew when converting asciinema recording to animated SVG:
          # - https://github.com/selectel/pyte/issues/178
          # - https://github.com/selectel/pyte/pull/180
          patches = (if oldAttrs ? patches then oldAttrs.patches else [ ]) ++ [
            (pkgs.fetchpatch {
              url = "https://patch-diff.githubusercontent.com/raw/selectel/pyte/pull/180.patch";
              hash = "sha256-/1dVU3WyWRSkGL708ulAn9UKgwBJiB90tFfdrXxg+ac=";
            })
          ];
        });
      };
    }).pkgs;
})
