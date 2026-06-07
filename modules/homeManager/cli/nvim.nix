{
  pkgs,
  config,
  lib,
  ...
}:

{
  options.homeModules.cli.neovim.enable = lib.mkEnableOption "enable neovim";

  config = lib.mkIf config.homeModules.cli.neovim.enable {
    home.packages = [
      (pkgs.neovim.override {
        vimAlias = true;
        viAlias = true;
        withNodeJs = true;
        withPython3 = true;
        withRuby = false;
      })

      # CLI Utilities & Neovim Dependencies
      pkgs.imagemagick
      pkgs.fd
      pkgs.ripgrep
      pkgs.unzip
      pkgs.wget
      pkgs.tree-sitter

      # Linters
      pkgs.hadolint
      pkgs.commitlint
      pkgs.dotenv-linter

      # Language Servers
      pkgs.bash-language-server # Bash
      pkgs.tailwindcss-language-server # Tailwind
      pkgs.vscode-langservers-extracted # HTML/CSS/JSON
      pkgs.dockerfile-language-server # Dockerfile
      pkgs.harper # Spell checking
    ] ++ lib.optionals pkgs.stdenv.isDarwin [
      pkgs.pngpaste
    ];

    # Set default editor to be nvim
    home.sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      SUDO_EDITOR = "nvim";
      MANPAGER = "nvim +Man!";
    };
  };
}
