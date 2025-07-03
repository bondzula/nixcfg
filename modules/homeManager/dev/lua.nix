{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.homeModules.dev.lua.enable = lib.mkEnableOption "Enable Lua Module";

  config = lib.mkIf config.homeModules.dev.lua.enable {
    home.packages = with pkgs; [
      lua51Packages.lua
      lua51Packages.luarocks
      lua51Packages.luacheck
      stylua
      lua-language-server
    ];
  };
}
