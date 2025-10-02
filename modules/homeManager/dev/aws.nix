{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.homeModules.dev.aws.enable = lib.mkEnableOption "Enable AWS Module";

  config = lib.mkIf config.homeModules.dev.aws.enable {
    home.packages = with pkgs; [
      awscli2
      ssm-session-manager-plugin
    ];
  };
}
