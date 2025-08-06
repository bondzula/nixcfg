{
  pkgs,
  ...
}:

{
  imports = [
    ../../modules/homeManager
  ];

  home = {
    username = "bondzula";
    homeDirectory = "/home/bondzula";

    packages = with pkgs; [

    ];

    stateVersion = "24.11";
  };

  homeModules = {
    cli = {
      atuin.enable = true;
      direnv.enable = true;
      fzf.enable = true;
      git = {
        enable = true;
        signing = {
          enable = true;
          key = "220F3B2DB85ED723";
        };
      };
      gpg.enable = true;
      neovim.enable = true;
      ripgrep.enable = true;
      zoxide.enable = true;
      zsh.enable = true;
    };

    dev = {
      aws.enable = true;
      c.enable = true;
      go.enable = true;
      javascript.enable = true;
      lua.enable = true;
      nix.enable = true;
      php.enable = true;
      python.enable = true;
      rust.enable = true;
      terraform.enable = true;
      zig.enable = true;
    };

  };

  programs.home-manager.enable = true;
}