{
  lib,
  config ? { },
}:
let
  selflib = import ./lib.nix lib;
  compositor = config.compositor or { };
  font = config.font or { };
  background = config.background or { };
  terminal = config.terminal or "foot";

  settings = lib.recursiveUpdate {
    general = {
      gaps_in = 5;
      gaps_out = 20;
      border_size = 2;
      layout = config.layout or "dwindle";
    };

    misc = {
      disable_hyprland_logo = true;
      disable_splash_rendering = true;
      background_color = background.color or "0xff000000";
      font_family = font.family or "Sans";
    };

    input = {
      kb_layout = "us";
    };
  } compositor;

  keybindings = lib.recursiveUpdate {
    "SUPER + Return" = terminal;
    "SUPER + Space" = config.launcher or "fuzzel";
  } (config.keybindings or { });
in
selflib.toBreaklandLua {
  inherit settings keybindings;
}
