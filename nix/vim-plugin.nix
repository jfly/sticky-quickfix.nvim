{
  self,
  inputs,
  withSystem,
  ...
}:
{

  imports = [
    inputs.flake-parts.flakeModules.modules
  ];

  flake.modules.nixvim.default = self.modules.nixvim.sticky-quickfix;
  flake.modules.nixvim.sticky-quickfix =
    { lib, pkgs, ... }:
    let
      self' = withSystem pkgs.system ({ self', ... }: self');
    in
    lib.nixvim.neovim-plugin.mkNeovimPlugin {
      name = "sticky-quickfix";
      package = lib.mkPackageOption self'.packages "sticky-quickfix" { };
      maintainers = [ lib.maintainers.jfly ];
    };

  perSystem =
    {
      self',
      lib,
      pkgs,
      ...
    }:
    {
      packages.default = self'.packages.sticky-quickfix;

      packages.sticky-quickfix = pkgs.vimUtils.buildVimPlugin {
        pname = "sticky-quickfix.nvim";
        version = "1.0.0";
        src = lib.fileset.toSource {
          root = ../.;
          fileset = ../lua;
        };
      };
    };
}
