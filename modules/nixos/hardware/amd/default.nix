{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
    ;
  cfg = config.nixosModules.hardware.amd;
  hardware = config.nixosModules.hardware;
  mkHasOption =
    description:
    mkOption {
      default = false;
      type = types.bool;
      description = ''
        Whether the device has ${description}.
      '';
    };
in
{
  options = {
    nixosModules.hardware.has.amd.gpu = mkHasOption "an AMD GPU";
    nixosModules.hardware.amd = {
      gpu = {
        enableEarlyModesetting = mkOption {
          default = hardware.has.amd.gpu;
          defaultText = lib.literalExpression "config.nixosModules.hardware.has.amd.gpu";
          type = lib.types.bool;
          description = ''
            Whether to enable early kernel modesetting.
          '';
        };
        enableBacklightControl = mkOption {
          default = hardware.has.amd.gpu;
          defaultText = lib.literalExpression "config.nixosModules.hardware.has.amd.gpu";
          type = lib.types.bool;
          description = ''
            Whether to loosen access to the backlight device nodes.
          '';
        };
      };
    };
  };
  config = mkMerge [
    (mkIf hardware.has.amd.gpu {
      # AMD GPU is expected to work out of the box.
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };
    })
    (mkIf cfg.gpu.enableEarlyModesetting {
      boot.initrd.kernelModules = [
        "amdgpu"
      ];
      # Firmware is required in stage-1 for early KMS.
      hardware.enableRedistributableFirmware = true;
    })
    (mkIf (cfg.gpu.enableBacklightControl) {
      # Enables brightness slider in Steam
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chmod a+w /sys/class/backlight/%k/brightness"
      '';
    })
  ];
}
