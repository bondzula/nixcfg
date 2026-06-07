{ config, lib, ... }:

{
  options.homeModules.cli.ssh = {
    enable = lib.mkEnableOption "enable SSH client configuration with GPG agent";
  };

  config = lib.mkIf config.homeModules.cli.ssh.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      settings = {
        "*" = {
          # Security settings
          HashKnownHosts = true;

          # Connection settings
          ServerAliveInterval = 60;
          ServerAliveCountMax = 3;

          PasswordAuthentication = "no";
          ChallengeResponseAuthentication = "no";
        };
      };
    };

    # Ensure GPG agent has SSH support enabled
    services.gpg-agent.enableSshSupport = lib.mkForce true;

    # Set SSH_AUTH_SOCK to use GPG agent
    home.sessionVariables = {
      SSH_AUTH_SOCK = "$(gpgconf --list-dirs agent-ssh-socket)";
    };
  };
}
