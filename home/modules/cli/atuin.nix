{ config, lib, ... }:

{
  options.homeModules.cli.atuin.enable = lib.mkEnableOption "enable atuin";

  config = lib.mkIf config.homeModules.cli.atuin.enable {
    programs.atuin = {
      enable = true;
      flags = [
        "--disable-up-arrow"
      ];
      settings = {
        style = "compact";
        inline_height = 20;
      };
      enableZshIntegration = true;
    };
  };
}
