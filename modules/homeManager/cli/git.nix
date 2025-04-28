{ config, lib, ... }:

{
  options.homeModules.cli.git.enable = lib.mkEnableOption "enable git";

  config = lib.mkIf config.homeModules.cli.git.enable {
    programs.git = {
      enable = true;
      userName = "Stefan Bondzulic";
      userEmail = "stefanbondzulic@gmail.com";

      extraConfig = {
        init.defaultBranch = "main";
        featch.prune = true;
        pull.rebase = true;
        merge.conflictstyle = "diff3";
        diff.external = "difft";
      };
    };

    # Enable GitHub CLI as well
    programs.gh = {
      enable = true;
      settings = {
        git_protocol = "ssh";
      };
    };
  };
}
