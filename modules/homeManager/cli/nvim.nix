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

        unzip
        wget
        tree-sitter

        # Rust
        cargo
        rustc

        hadolint
        commitlint
        dotenv-linter

        # Language Servers
        zls # Zig
        nixd # Nix
        gopls # Go
        pyright # Python
        intelephense # PHP
        terraform-ls # Terraform
        lua-language-server # Lua
        vue-language-server # Vue
        bash-language-server # Bash
        cmake-language-server # Cmake
        typescript-language-server # JS/TS
        tailwindcss-language-server # Tailwind
        vscode-langservers-extracted # HTML/CSS/JSON
        dockerfile-language-server-nodejs # Dockerfile
      ];
    };

    # home.file.".config/nvim" = {
    #   source = "${inputs.dotfiles}/nvim";
    #   recursive = true;
    # };

    # Set default editor to be nvim
    home.sessionVariables = {
      EDITOR = "${pkgs.neovim}/bin/nvim";
      VISUAL = "${pkgs.neovim}/bin/nvim";
      SUDO_EDITOR = "${pkgs.neovim}/bin/nvim";
      MANPAGER = "nvim +Man!";
    };
  };
}
