{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.nixosModules.gaming.enable = lib.mkEnableOption "enable gaming module";

  config = lib.mkIf config.nixosModules.gaming.enable {
    hardware.openrazer = {
      enable = true;
      users = [ "bondzula" ];
    };

    programs = {
      steam = {
        enable = true;
        gamescopeSession.enable = true;
      };
      gamescope.enable = true; # cli wrapper
      gamemode.enable = true;
    };

    # Proton-GE etc.
    environment.sessionVariables.STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/bondzula/.steam/root/compatibilitytools.d";

    environment.systemPackages = with pkgs; [
      protonup
      mangohud
      goverlay
      lutris
    ];
  };
}
