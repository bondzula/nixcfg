{ pkgs, ... }:

{
  home.packages = with pkgs; [
    go
    gopls
    goimports-reviser
    gofumpt
    golines
    go-blueprint
  ];
}
