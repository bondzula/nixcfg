{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nixd
    deadnix
    statix
    nixfmt-rfc-style
  ];
}
