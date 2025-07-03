{
  pkgs,
  inputs,
  outputs,
  ...
}:

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

        packages = with pkgs; [ ];

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

        desktop = {
          fonts.enable = true;
        };
      };

      programs.home-manager.enable = true;
    };
  };

}
