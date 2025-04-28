{ pkgs, inputs, outputs, ... }:

{
  imports = [
    inputs.home-manager.darwinModules.home-manager
  ];

  # Home Manager setup
  home-manager = {
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs outputs; };
    users.stefan = {
      imports = [
        ../../modules/homeManager
      ];

      home = {
        username = "stefan";
        homeDirectory = "/Users/stefan";

        packages = with pkgs; [
          appcleaner
          discord
          exercism
          firefox
          google-chrome
          monitorcontrol
          raycast
          vscode
          zed-editor

          # go-blueprint
          # awscli2
          # ssm-session-manager-plugin
          # terraform
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

