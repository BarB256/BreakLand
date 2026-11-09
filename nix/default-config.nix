{
  font = {
    family = "Sans";
    size = 11;
  };

  background = {
    color = "0xff000000";
  };

  terminal = "ghostty";
  fileManager = "dolphin";
  launcher = "fuzzel";

  compositor = {
    general = {
      gaps_in = 5;
      gaps_out = 20;
      border_size = 2;
      layout = "dwindle";
    };

    input = {
      kb_layout = "us";
      follow_mouse = 1;
    };

    misc = {
      disable_hyprland_logo = true;
      disable_splash_rendering = true;
      background_color = "0xff000000";
      font_family = "Sans";
    };
  };

  keybindings = {
    "SUPER + Return" = "ghostty";
    "SUPER + Q" = "ghostty";
    "SUPER + E" = "dolphin";
    "SUPER + Space" = "fuzzel";
    "SUPER + R" = "fuzzel";
    "SUPER + L" = "breakland-shell --lock";
  };

  viewport = {
    enable = false;
    leftMonitor = "DP-1";
    rightMonitor = "DP-2";
    maxPosition = 5;
  };
}
