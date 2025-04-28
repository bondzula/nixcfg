{ config, lib, ... }:

{
  options.homeModules.cli.direnv.enable = lib.mkEnableOption "enable direnv";

  config = lib.mkIf config.homeModules.cli.direnv.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
      config = {
        global = {
          hide_env_diff = true;
        };
      };
    };
  };
}
