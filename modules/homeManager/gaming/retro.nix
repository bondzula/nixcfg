{
  config,
  lib,
  pkgs,
  ...
}:

let
  emuRoot = "/mnt/rust/games/emulation";
  saves = "${emuRoot}/saves";
  bios = "${emuRoot}/bios";
  roms = "${emuRoot}/roms";
  storage = "${emuRoot}/storage";
  tools = "${emuRoot}/tools";
in
{
  options.homeModules.gaming.retro = {
    enable = lib.mkEnableOption "enable retro gaming emulators and configs";
  };

  config = lib.mkIf config.homeModules.gaming.retro.enable {
    # Packages for this feature
    home.packages = with pkgs; [
      # retroarch-full
      # dolphin-emu
      # pcsx2
      # rpcs3
      # duckstation
      # melonDS
      # ppsspp
      # scummvm
      # vita3k
      # xenia
      # cemu
    ];

    programs.retroarch = {
      enable = true;
      settings = {
        savefile_directory = "${saves}/retroarch";
        savestate_directory = "${saves}/retroarch";
        system_directory = bios;
        rgui_browser_directory = roms;
        thumbnails_directory = "${tools}/downloaded_media";
      };
    };

    # xdg.enable = true;
    # xdg.configFile = {
    #   "dolphin-emu/Dolphin.ini".text = ''
    #     [General]
    #     ISOPaths = 2
    #     ISOPath0 = ${roms}/gc
    #     ISOPath1 = ${roms}/wii
    #     RecursiveISOPaths = True
    #     NANDRootPath = ${storage}/dolphin/Wii
    #     WiiSDCardPath = ${storage}/dolphin/Wii/sd.raw
    #     DumpPath = ${storage}/dolphin/Dump
    #     LoadPath = ${storage}/dolphin/Load
    #     ResourcePackPath = ${storage}/dolphin/ResourcePacks
    #   '';
    #
    #   "PCSX2/inis/PCSX2.ini".text = ''
    #     [Folders]
    #     Bios = ${bios}/pcsx2
    #     MemoryCards = ${saves}/pcsx2
    #     UseDefaultBios = False
    #     UseDefaultMemoryCards = False
    #   '';
    #
    #   "rpcs3/vfs.yml".text = ''
    #     /dev_hdd0/: ${storage}/rpcs3/dev_hdd0
    #   '';
    #
    #   "Ryujinx/Config.json".text = ''
    #     {
    #       "system_directory": "${bios}/ryujinx",
    #       "save_directory": "${saves}/ryujinx"
    #     }
    #   '';
    #
    #   "duckstation/settings.ini".text = ''
    #     [Main]
    #     BIOSDirectory = ${bios}/duckstation
    #     MemoryCardDirectory = ${saves}/duckstation
    #   '';
    #
    #   "melonDS/melonDS.ini".text = ''
    #     [Paths]
    #     BIOSPath = ${bios}/melonds
    #     SavePath = ${saves}/melonds
    #   '';
    #
    #   "ppsspp/PSP/SYSTEM/ppsspp.ini".text = ''
    #     [General]
    #     MemStickDirectory = ${storage}/ppsspp
    #   '';
    #
    #   "scummvm/scummvm.ini".text = ''
    #     [scummvm]
    #     path = ${roms}/scummvm
    #     savepath = ${saves}/scummvm
    #     extrapath = ${bios}/scummvm/extra
    #   '';
    #
    #   "Vita3K/config.yml".text = ''
    #     pref-path: ${storage}/vita3k
    #   '';
    #
    #   "xenia/xenia.config.toml".text = ''
    #     content_root = ${saves}/xenia
    #   '';
    #
    #   "Cemu/settings.xml".text = ''
    #     <mlc_path>${storage}/cemu/mlc01</mlc_path>
    #   '';
    # };
  };
}
