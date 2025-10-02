{ config, lib, pkgs, ... }:

{
  options.homeModules.cli.git = {
    enable = lib.mkEnableOption "enable git";
    signing = {
      enable = lib.mkEnableOption "enable commit signing" // { default = false; };
      key = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "GPG key ID for signing commits";
      };
    };
  };

  config = lib.mkIf config.homeModules.cli.git.enable {
    programs.git = {
      enable = true;
      userName = "Stefan Bondzulic";
      userEmail = "stefanbondzulic@gmail.com";

      signing = lib.mkIf config.homeModules.cli.git.signing.enable {
        signByDefault = true;
        key = config.homeModules.cli.git.signing.key;
      };

      extraConfig = {
        init.defaultBranch = "main";
        fetch.prune = true;  # Fixed typo: was "featch"
        pull.rebase = true;
        merge.conflictstyle = "diff3";
        diff.external = "difft";
        
        # GPG configuration for signing
        gpg = lib.mkIf config.homeModules.cli.git.signing.enable {
          program = "${pkgs.gnupg}/bin/gpg";
        };
        
        # Better SSH configuration
        core = {
          sshCommand = "ssh";
        };
        
        # Credential caching for HTTPS (optional)
        credential = {
          helper = "cache --timeout=3600";
        };
      };
    };

    # Enable GitHub CLI as well
    programs.gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
        prompt = "enabled";
      };
    };
  };
}
