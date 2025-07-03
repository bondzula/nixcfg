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
      nodejs
      nodePackages.npm
      nodePackages.jsonlint
      bun
      eslint
      eslint_d
      prettier
      prettierd
      vue-language-server
      typescript-language-server
    ];
  };
}
