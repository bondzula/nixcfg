{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.homeModules.dev.zig.enable = lib.mkEnableOption "Enable Zig Module";

  config = lib.mkIf config.homeModules.dev.zig.enable {
    home.packages = with pkgs; [
      zig
      zls
    ];
  };
}
