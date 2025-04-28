{ config, lib, pkgs, ... }:

{
  options.nixosModules.podman.enable = lib.mkEnableOption "enable podman";

  config = lib.mkIf config.nixosModules.podman.enable {
    virtualisation = {
      podman = {
        enable = true;
        dockerCompat = true;
        autoPrune = {
          enable = true;
          dates = "weekly";
          flags = [
            "--filter=until=24h"
            "--filter=label!=important"
          ];
        };
        defaultNetwork.settings.dns_enabled = true;
      };
    };
    environment.systemPackages = with pkgs; [
      podman-compose
    ];
  };
}


