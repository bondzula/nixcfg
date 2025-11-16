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
        inputs.noctalia.homeModules.default
      ];

      home = {
        username = "bondzula";
        homeDirectory = "/home/bondzula";

        packages = with pkgs; [
          discord
          firefox
          obs-studio
          obsidian
          ticktick
          vscode
          wowup-cf
          zed-editor
          google-chrome
          claude-code
          codex
          nautilus
        ];

        stateVersion = "24.11";
      };

      programs.chromium = {
        enable = true;
        package = pkgs.chromium;
        commandLineArgs = [
          "--enable-features=WebUIDarkMode"
          "--force-dark-mode"
          "--gtk-version=4"
        ];
      };

      homeModules = {
        cli = {
          atuin.enable = true;
          direnv.enable = true;
          fzf.enable = true;
          git = {
            enable = true;
            signing = {
              enable = true;
              key = "178B9BECF5202296";
            };
          };
          gpg.enable = true;
          neovim.enable = true;
          ripgrep.enable = true;
          ssh.enable = true;
          zoxide.enable = true;
          zsh.enable = true;
          tmux.enable = true;
        };

        dev = {
          aws.enable = true;
          c.enable = true;
          go.enable = true;
          javascript.enable = true;
          lua.enable = true;
          nix.enable = true;
          php.enable = true;
          python.enable = true;
          rust.enable = true;
          terraform.enable = true;
          zig.enable = true;
        };

        gaming = {
          retro.enable = true;
        };

        desktop = {
          ghostty.enable = true;
          fonts.enable = true;
        };
      };

      # # configure options
      # programs.noctalia-shell = {
      #   enable = true;
      #   settings = {
      #     bar = {
      #       backgroundOpacity = 0.8;
      #       floating = true;
      #     };
      #     colorSchemes.predefinedScheme = "Monochrome";
      #     general = {
      #       avatarImage = "/home/drfoobar/.face";
      #       radiusRatio = 0.2;
      #     };
      #     location = {
      #       name = "Pozega, Serbia";
      #     };
      #     wallpaper = {
      #       enabled = true;
      #       overviewEnabled = true;
      #     };
      #     dock = {
      #       enabled = false;
      #     };
      #     network = {
      #       wifiEnabled = false;
      #     };
      #   };
      # };

      programs.home-manager.enable = true;
    };
  };

}
