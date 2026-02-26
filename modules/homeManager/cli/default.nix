{ pkgs, ... }:

{
  imports = [
    ./atuin.nix
    ./direnv.nix
    ./fzf.nix
    ./git.nix
    ./gpg.nix
    ./nvim.nix
    ./ssh.nix
  ];

  programs.btop = {
    enable = true;
  };

  programs.bat = {
    enable = true;
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    extraOptions = [
      "-l"
      "--icons"
      "--git"
      "-a"
    ];
  };

  home.packages = with pkgs; [
    coreutils
    dig
    fd
    htop
    httpie
    jq
    fastfetch
    procs
    ripgrep
    rsync
    tealdeer
    tree
    wakeonlan
    wget
    zip
    curl
    sesh
    stow
    yazi
    zsh
    tmux
    zoxide
  ];
}
