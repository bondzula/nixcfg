{
  config,
  lib,
  pkgs,
  ...
}:
let
  useGcc = config.homeModules.dev.c.preferGcc;

  compiler = if useGcc then pkgs.gcc else pkgs.clang;
  debugger = if useGcc then pkgs.gdb else pkgs.lldb;
in
{
  options.homeModules.dev.c = {
    enable = lib.mkEnableOption "Enable C / C++ Module";
    preferGcc = lib.mkOption {
      type = lib.types.bool;
      default = pkgs.stdenv.isDarwin;
      description = "Whether to prefer GCC over Clang";
    };
  };

  config = lib.mkIf config.homeModules.dev.c.enable {
    home.packages =
      with pkgs;
      [
        cmake
        gnumake
        clang-tools # Works well on both systems for LSP/formatting
        pkg-config
        cmake-language-server
      ]
      ++ [
        compiler
        debugger
      ];
  };
}
