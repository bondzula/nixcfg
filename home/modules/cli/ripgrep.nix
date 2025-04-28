{ pkgs, config, lib, ... }:

{
  options.homeModules.cli.ripgrep.enable = lib.mkEnableOption "enable ripgrep";

  config = lib.mkIf config.homeModules.cli.ripgrep.enable {
    home = {
      # Intall ripgrep
      packages = [ pkgs.ripgrep ];

      # Set ripgrep's config path to avoid polluting the home directory
      sessionVariables = {
        RIPGREP_CONFIG_PATH = "${config.xdg.configHome}/ripgrep/config";
      };


      # ripgrep ignores anything matching this
      file.".ignore".text = ''
        # Don't ignore .env file
        !.env
        # Don't ignore laravel.log
        !laravel.log

        .git/
        *.swp
        # Minified files
        *.min.css
        *.css.map
        *.min.js
        *.js.map
        # Compiled files
        .sass-cache/
        .obsidian
      '';
    };

    # Configure ripgrep
    xdg.configFile."ripgrep/config".text = ''
      # Set colors
      # Matches are blue
      --colors=match:fg:38,139,210
      # Line numbers are dark grey and bold
      --colors=line:fg:88,110,117
      --colors=line:style:bold
      # Paths are dark grey and bold
      --colors=path:fg:88,110,117
      --colors=path:style:bold
      # Search hidden files and directories
      --hidden
      # Searches case insensitively if the pattern is all lowercase. Search case sensitively otherwise.
      --smart-case
    '';

  };
}
