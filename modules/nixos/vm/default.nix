{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.nixosModules.vm;
in
{
  options.nixosModules.vm = {
    enable = lib.mkEnableOption "virtual machine tooling (libvirt, SPICE, VirtIO)";
    user = lib.mkOption {
      type = lib.types.str;
      default = "bondzula";
      description = "User that should be added to the libvirtd group.";
      example = "alice";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.dconf.enable = true;

    users.users.${cfg.user}.extraGroups = [ "libvirtd" ];

    environment.systemPackages = with pkgs; [
      virt-manager
      virt-viewer
      spice
      spice-gtk
      spice-protocol
      virtio-win
      win-spice
      adwaita-icon-theme
      wrangler
      pavucontrol
    ];

    virtualisation = {
      libvirtd = {
        enable = true;
        qemu = {
          swtpm.enable = true;
        };
      };
      spiceUSBRedirection.enable = true;
    };

    services.spice-vdagentd.enable = true;
  };
}
