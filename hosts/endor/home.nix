{
  pkgs,
  inputs,
  outputs,
  ...
}:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs outputs; };
    users.bondzula = {
      imports = [
        ../../modules/homeManager
      ];

      home = {
        username = "bondzula";
        homeDirectory = "/home/bondzula";

        packages = with pkgs; [
          discord
          firefox
          ghostty
          google-chrome
          jellyfin-media-player
          obs-studio
          obsidian
          razergenie
          ticktick
          vscode
          wowup-cf
          zed-editor
        ];

        stateVersion = "24.11";
      };

      homeModules = {
        cli = {
          atuin.enable = true;
          direnv.enable = true;
          fzf.enable = true;
          git.enable = true;
          neovim.enable = true;
          ripgrep.enable = true;
          zoxide.enable = true;
          zsh.enable = true;
        };

        desktop = {
          fonts.enable = true;
        };
      };

      programs.home-manager.enable = true;
    };
  };

}
