{ config, lib, pkgs, ... }:

{
  options.homeModules.cli.ssh = {
    enable = lib.mkEnableOption "enable SSH client configuration with GPG agent";
  };

  config = lib.mkIf config.homeModules.cli.ssh.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      matchBlocks = {
        "*" = {
          # Security settings
          hashKnownHosts = true;

          # Connection settings
          serverAliveInterval = 60;
          serverAliveCountMax = 3;

          # Reuse connections for faster subsequent connections
          controlMaster = "auto";
          controlPath = "~/.ssh/sockets/%r@%h-%p";
          controlPersist = "600";

          extraOptions = {
            PasswordAuthentication = "no";
            ChallengeResponseAuthentication = "no";
          };
        };

        "github.com" = {
          hostname = "github.com";
          user = "git";
        };

        "gitlab.com" = {
          hostname = "gitlab.com";
          user = "git";
        };

        "*.local 192.168.*" = {
          extraOptions = {
            StrictHostKeyChecking = "no";
            UserKnownHostsFile = "/dev/null";
          };
        };
        "atreides" = {
          hostname = "192.168.0.20";
          user = "bondzula";
          extraOptions = {
            PubKeyAuthentication = "unbound";
            IdentitiesOnly = "yes";
          };
        };

      };
    };
    
    # Create SSH sockets directory for connection multiplexing
    home.file.".ssh/sockets/.keep".text = "";
    
    # Ensure GPG agent has SSH support enabled
    services.gpg-agent.enableSshSupport = lib.mkForce true;
    
    # Set SSH_AUTH_SOCK to use GPG agent
    home.sessionVariables = {
      SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
    };
  };
}
