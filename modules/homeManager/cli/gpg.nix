{ config, lib, pkgs, ... }:

{
  options.homeModules.cli.gpg = {
    enable = lib.mkEnableOption "enable GPG";
  };

  config = lib.mkIf config.homeModules.cli.gpg.enable {
    programs.gpg = {
      enable = true;
      settings = {
        trust-model = "tofu+pgp";
        use-agent = true;
        no-emit-version = true;
        no-comments = true;
      };
    };

    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      pinentry.package = if pkgs.stdenv.isDarwin 
        then pkgs.pinentry_mac 
        else pkgs.pinentry-curses;
      defaultCacheTtl = 600;
      maxCacheTtl = 7200;
    };

    # Ensure GPG directory exists with proper permissions
    home.file.".gnupg/.keep".text = "";
  };
}