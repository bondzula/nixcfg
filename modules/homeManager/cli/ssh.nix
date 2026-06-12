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

          # Use 1Password SSH agent
          IdentityAgent = "~/.1password/agent.sock";
        };
      };
    };
  };
}
