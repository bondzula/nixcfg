{
  pkgs,
  config,
  lib,
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
      extraPackages =
        with pkgs;
        [
          imagemagick
          fd
          ripgrep
          unzip
          wget
          tree-sitter

          hadolint
          commitlint
          dotenv-linter

          # Language Servers
          bash-language-server # Bash
          tailwindcss-language-server # Tailwind
          vscode-langservers-extracted # HTML/CSS/JSON
          dockerfile-language-server-nodejs # Dockerfile
          harper # Spell checking
        ]
        ++ lib.optionals pkgs.stdenv.isDarwin [
          pngpaste
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
