{ pkgs, ... }:

{
  imports = [
    ../../modules/homeManager
  ];

  home = {
    username = "bondzula";
    homeDirectory = "/home/bondzula";

    packages = with pkgs; [ mariadb ];

    stateVersion = "25.05";
  };

  homeModules = {
    cli = {
      atuin.enable = true;
      direnv.enable = true;
      fzf.enable = true;
      git.enable = true;
      herdr.enable = true;
      neovim.enable = true;
      ssh.enable = true;
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
