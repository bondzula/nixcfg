{ modulesPath, pkgs, ... }:

{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ../../modules/nixos
  ];

  networking.hostName = "richese";

  nix.settings.sandbox = false;
  nixpkgs.hostPlatform = "x86_64-linux";

  proxmoxLXC = {
    manageNetwork = false;
    privileged = false;
  };

  time.timeZone = "Europe/Belgrade";
  i18n.defaultLocale = "en_US.UTF-8";

  virtualisation.docker = {
    enable = true;
  };

  users = {
    users.bondzula = {
      initialHashedPassword = "$y$j9T$lTYSuKE.0BiJazE5fJ72B0$XMEo8mlRwfxuT6Q8bDielkRNGIFy.To2qsEYw7hbIm/";
      isNormalUser = true;
      description = "Stefan Bondzulic";
      extraGroups = [ "wheel" "docker" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINF99lU/SLfVoC/Vua9Zbu58d57HfrZZNOZMuI/0xteL openpgp:0x2EED2F74"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINjo2o1vRJTER5HHNZRGHlYW9gxjqCngGKxhVN/EEtLF openpgp:0xACE015E2"
      ];
    };
    groups.bondzula.gid = 1000;
  };

  environment.systemPackages = with pkgs; [
    git neovim
  ];

  services.openssh = {
    enable = true;
    allowSFTP = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  networking.firewall.enable = false;

  system.stateVersion = "24.11";
}

