{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.homeModules.dev.python.enable = lib.mkEnableOption "Enable Python Module";

  config = lib.mkIf config.homeModules.dev.python.enable {
    home.packages = with pkgs; [
      uv
      ruff
      black
      pyright
    ];
  };
}
