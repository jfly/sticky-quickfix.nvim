{
  perSystem =
    { pkgs, ... }:
    {
      # Yeah, not a lot going on here :p. But without this, I guess we end up
      # loading a shell based on the inputs to the default package, which
      # clobbers `vi`, `vim, and `nvim` on my machine. No thank you!
      devShells.default = pkgs.mkShell { };
    };
}
