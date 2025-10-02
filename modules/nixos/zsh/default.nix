{
  lib,
  config,
  pkgs,
  ...
}:

{
  options.nixosModules.zsh.enable = lib.mkEnableOption "Enable ZSH";

  config = lib.mkIf config.nixosModules.zsh.enable {
    # Enables the zsh shell
    programs.zsh.enable = true;

    # Add zsh package to /etc/shells
    environment.shells = with pkgs; [ zsh ];

    # Sets default shell for all users to zsh
    users.defaultUserShell = pkgs.zsh;
  };
}
