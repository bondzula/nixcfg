{
  config,
  lib,
  pkgs,
  ...
}:

let
  gitCfg = config.homeModules.cli.git;
  signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG3jrrfHENkZhu81UP0vU9DjyiTir1ipZgvOsdF6rLDO";
  sshSignerProgram =
    if pkgs.stdenv.isDarwin then
      "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
    else
      "/opt/1Password/op-ssh-sign";
in
{
  options.homeModules.cli.git = {
    enable = lib.mkEnableOption "enable git";
  };

  config = lib.mkIf gitCfg.enable {
    programs.git = {
      enable = true;

      settings = {
        user = {
          name = "Stefan Bondzulic";
          email = "stefanbondzulic@gmail.com";
          signingkey = signingKey;
        };

        init.defaultBranch = "main";
        fetch.prune = true;
        pull.rebase = true;
        merge.conflictstyle = "diff3";
        diff.external = "difft";

        commit.gpgsign = true;
        gpg = {
          format = "ssh";
          ssh.program = sshSignerProgram;
        };

        core = {
          sshCommand = "ssh";
        };

        credential = {
          helper = "cache --timeout=3600";
        };
      };
    };

    programs.gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
        prompt = "enabled";
      };
    };
  };
}
