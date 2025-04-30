{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:

{
  options.homeModules.cli.neovim.enable = lib.mkEnableOption "enable neovim";

  config = lib.mkIf config.homeModules.cli.neovim.enable {
    programs.neovim = {
      enable = true;
      vimAlias = true;
      viAlias = true;
      withNodeJs = true;
      withPython3 = true;

      extraLuaPackages = ps: [ ps.magick ];
      extraPackages = with pkgs; [
        imagemagick
        fd
        ripgrep

        # pngpaste # Used for img-clip plugin

        # Build tools
        pkg-config
        gcc
        cmake
        gnumake
        ninja

        unzip
        wget
        tree-sitter

        # Node
        nodejs
        nodePackages.npm

        # Lua
        lua51Packages.lua
        lua51Packages.luarocks

        # PHP
        php82
        php82Packages.composer

        # Rust
        cargo
        rustc

        hadolint
        commitlint
        dotenv-linter
      ];
    };

    home.file.".config/nvim" = {
      source = "${inputs.dotfiles}/nvim";
      recursive = true;
    };

    # Set default editor to be nvim
    home.sessionVariables = {
      EDITOR = "${pkgs.neovim}/bin/nvim";
      VISUAL = "${pkgs.neovim}/bin/nvim";
      SUDO_EDITOR = "${pkgs.neovim}/bin/nvim";
      MANPAGER = "nvim +Man!";
    };
  };
}
