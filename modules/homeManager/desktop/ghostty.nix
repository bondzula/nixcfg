{ config, lib, ... }:

{
  options.homeModules.desktop.ghostty.enable = lib.mkEnableOption "Ghostty";

  config = lib.mkIf config.homeModules.desktop.ghostty.enable {
    programs.ghostty = {
      enable = true;
      systemd.enable = true;
    };
  };
}
