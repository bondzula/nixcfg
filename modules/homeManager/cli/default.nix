{pkgs, ...}:

{
  imports = [
    ./atuin.nix
    ./direnv.nix
    ./fzf.nix
    ./git.nix
    ./nvim.nix
    ./ripgrep.nix
    ./zoxide.nix
    ./zsh.nix
  ];

  programs.btop = {
    enable = true;
    settings = {
      vim_keys = true;
    };
  };

  programs.bat = {
    enable = true;
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    extraOptions = ["-l" "--icons" "--git" "-a"];
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  home.packages = with pkgs; [
    coreutils
    dig
    fd
    htop
    httpie
    jq
    neofetch
    procs
    ripgrep
    rsync
    tealdeer
    tree
    wakeonlan
    zip
  ];
}

