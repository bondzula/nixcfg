{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.homeModules.dev.go.enable = lib.mkEnableOption "Enable Go Module";

  config = lib.mkIf config.homeModules.dev.go.enable {
    home.packages = with pkgs; [
      go
      gopls
      goimports-reviser
      gofumpt
      golines
      go-blueprint
    ];
  };
}
