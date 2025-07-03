{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.homeModules.dev.rust.enable = lib.mkEnableOption "Enable Rust Module";

  config = lib.mkIf config.homeModules.dev.rust.enable {
    home.packages = with pkgs; [
      cargo
      rustc
      rust-analyzer
    ];
  };
}
