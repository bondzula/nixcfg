{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.homeModules.dev.c.enable = lib.mkEnableOption "Enable C / C++ Module";

  config = lib.mkIf config.homeModules.dev.c.enable {
    home.packages = with pkgs; [
      clang
      gcc
      cmake
      gnumake
      lldb
      gdb
      clang-tools
      pkg-config
      cmake-language-server
    ];
  };
}
