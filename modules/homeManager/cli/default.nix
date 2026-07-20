{ pkgs, ... }:

{
  imports = [
    ./atuin.nix
    ./direnv.nix
    ./fzf.nix
    ./git.nix
    ./gpg.nix
    ./herdr.nix
    ./nvim.nix
    ./ssh.nix
  ];

  home.packages = with pkgs; [
    bat
    btop
    coreutils
    curl
    dig
    eza
    fastfetch
    fd
    htop
    httpie
    jq
    procs
    ripgrep
    rsync
    sesh
    stow
    tealdeer
    tmux
    tree
    wakeonlan
    wget
    yazi
    zip
    zoxide
    zsh
  ];
}
