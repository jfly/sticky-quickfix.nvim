{ inputs, self, ... }:

{
  perSystem =
    {
      self',
      lib,
      pkgs,
      ...
    }:
    let

      termtosvg = pkgs.callPackage ./termtosvg.nix { };

      record-demo =
        playArgs:
        pkgs.runCommand "record-demo" { } ''
          mkdir $out
          ${lib.getExe self'.packages.play-demo} ${playArgs} $out/demo.cast
          ${lib.getExe termtosvg} render $out/demo.cast $out/demo.svg --template progress_bar
        '';
    in
    {
      packages.neovim-demo = inputs.nixvim.legacyPackages.${pkgs.system}.makeNixvimWithModule {
        inherit pkgs;

        module = {
          imports = [
            self.modules.nixvim.sticky-quickfix
          ];

          plugins.lsp.enable = true;
          plugins.lsp.servers.ruff.enable = true;

          plugins.sticky-quickfix.enable = true;
          opts.number = true;
        };
      };

      packages.play-demo = pkgs.writeShellApplication {
        name = "play-demo";
        runtimeInputs = [
          (pkgs.python3.withPackages (ps: [ ps.pexpect ]))
          pkgs.asciinema
          self'.packages.neovim-demo
        ];
        text = ''
          export ASCIINEMA_INSTALL_ID=nix-build
          # Neovim wants to create swap files in $HOME
          export HOME
          HOME=$(mktemp -d)

          exec python ${./demo.py} "$@"
        '';
      };

      # Vanilla neovim.
      packages.record-demo-before = record-demo "--no-plugin";

      # Neovim with this plugin.
      packages.record-demo-after = record-demo "--plugin";
    };
}
