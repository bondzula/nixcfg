{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.homeModules.dev.nix.enable = lib.mkEnableOption "Enable Nix Module";

  config = lib.mkIf config.homeModules.dev.nix.enable {
    home.packages = with pkgs; [
      nixd
      deadnix
      statix
      nixfmt-rfc-style
    ];
  };
}
