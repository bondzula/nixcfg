{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.homeModules.dev.php.enable = lib.mkEnableOption "Enable PHP Module";

  config = lib.mkIf config.homeModules.dev.php.enable {
    home.packages = with pkgs; [
      php83
      php83Packages.composer
      php83Packages.phpstan
      php83Packages.php-cs-fixer
      intelephense
    ];
  };
}
