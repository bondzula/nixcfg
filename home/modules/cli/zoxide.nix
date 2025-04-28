{ config, lib, ... }:

{
  options.homeModules.cli.zoxide.enable = lib.mkEnableOption "enable zoxide";

  config = lib.mkIf config.homeModules.cli.zoxide.enable {
    programs.zoxide = {
      enable = true;
      options = [ "--cmd cd" ];
      enableZshIntegration = true;
    };
  };
}
