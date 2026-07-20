{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  options.homeModules.cli.herdr.enable = lib.mkEnableOption "enable Herdr";

  config = lib.mkIf config.homeModules.cli.herdr.enable {
    home.packages = [
      inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
