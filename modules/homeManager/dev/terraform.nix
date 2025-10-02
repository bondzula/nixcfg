{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.homeModules.dev.terraform.enable = lib.mkEnableOption "Enable Terraform Module";

  config = lib.mkIf config.homeModules.dev.terraform.enable {
    home.packages = with pkgs; [
      terraform
      tflint
      terraform-ls
    ];
  };
}
