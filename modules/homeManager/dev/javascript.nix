{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.homeModules.dev.javascript.enable = lib.mkEnableOption "Enable JavaScript Module";

  config = lib.mkIf config.homeModules.dev.javascript.enable {
    home.packages = with pkgs; [
      nodejs_20
      nodePackages.jsonlint
      pnpm
      bun
      eslint
      eslint_d
      # prettier # FIXME: Conflict with the composer package
      prettierd
      vue-language-server
      astro-language-server
      typescript-language-server
    ];

    # Configure npm to install global packages to home directory
    home.file.".npmrc".text = ''
      prefix=${config.home.homeDirectory}/.npm-global
    '';

    # Add npm global packages to PATH
    home.sessionPath = [
      "${config.home.homeDirectory}/.npm-global/bin"
    ];

    # Set NODE_PATH for global modules
    home.sessionVariables = {
      NODE_PATH = "${config.home.homeDirectory}/.npm-global/lib/node_modules";
    };
  };
}
