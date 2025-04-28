{ pkgs, lib, inputs, outputs, ... }:

{
  imports = [
    ../modules
  ];

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.stable-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [ "root" "bondzula" ];
    };
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };
    optimise.automatic = true;
    registry = (lib.mapAttrs (_: flake: { inherit flake; }))
      ((lib.filterAttrs (_: lib.isType "flake")) inputs);
    nixPath = [ "/etc/nix/path" ];
  };

  # This snippet will print the diff after rebuild
  system.activationScripts.diff = {
    supportsDryActivation = true;
    text = ''
      ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff \
         /run/current-system "$systemConfig"
    '';
  };
}
