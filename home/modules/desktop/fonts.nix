{ config, lib, pkgs, ... }:

{
  options.homeModules.desktop.fonts.enable =
    lib.mkEnableOption "install additional fonts for desktop apps";

  config = lib.mkIf config.homeModules.desktop.fonts.enable {
    home.packages = with pkgs; [
      font-manager
      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
    ];
  };
}

