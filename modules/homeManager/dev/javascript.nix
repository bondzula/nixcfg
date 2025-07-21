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
      bun
      eslint
      eslint_d
      # prettier # FIXME: Conflict with the composer package
      prettierd
      vue-language-server
      typescript-language-server
    ];
  };
}
