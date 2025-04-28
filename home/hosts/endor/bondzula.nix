{ pkgs, ... }:

{
  imports = [
    ../common.nix
  ];

  home.username = "bondzula";
  home.homeDirectory = "/home/bondzula";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "24.11";

  # Home packages (Those are universal packages I want installed)
  home.packages = with pkgs; [
    code-cursor
    discord
    firefox
    ghostty
    google-chrome
    jellyfin-media-player
    obsidian
    obs-studio
    razergenie
    ticktick
    vscode
    wowup-cf
    zed-editor
  ];

  homeModules = {
    cli = {
      atuin.enable = true;
      direnv.enable = true;
      fzf.enable = true;
      git.enable = true;
      neovim.enable = true;
      ripgrep.enable = true;
      zoxide.enable = true;
      zsh.enable = true;
    };

    desktop = {
      fonts.enable = true;
    };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
