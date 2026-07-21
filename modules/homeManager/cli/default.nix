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
    croc
    curl
    dig
    eza
    fastfetch
    fd
    htop
    httpie
    hunk
    jq
    procs
    ripgrep
    rsync
    sendme
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
