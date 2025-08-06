{ config, lib, pkgs, ... }:

{
  options.homeModules.cli.ssh = {
    enable = lib.mkEnableOption "enable SSH client configuration with GPG agent";
  };

  config = lib.mkIf config.homeModules.cli.ssh.enable {
    programs.ssh = {
      enable = true;
      
      extraConfig = ''
        # Security settings
        PasswordAuthentication no
        ChallengeResponseAuthentication no
        HashKnownHosts yes
        
        # Connection settings
        ServerAliveInterval 60
        ServerAliveCountMax 3
        
        # Reuse connections for faster subsequent connections
        ControlMaster auto
        ControlPath ~/.ssh/sockets/%r@%h-%p
        ControlPersist 600
        
        # Common hosts
        Host github.com
          HostName github.com
          User git
          
        Host gitlab.com
          HostName gitlab.com
          User git
          
        # Local network - less strict
        Host *.local 192.168.*
          StrictHostKeyChecking no
          UserKnownHostsFile /dev/null
      '';
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