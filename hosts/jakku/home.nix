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

  # Home Manager setup
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
          firefox
          ghostty
          google-chrome
          vscode
          zed-editor
        ];

        stateVersion = "24.11";
      };

      programs.home-manager.enable = true;
    };
  };
}
