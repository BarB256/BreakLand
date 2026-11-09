{
  lib,
  config ? { },
}:
let
  selflib = import ./lib.nix lib;
  compositor = config.compositor or { };
  font = config.font or { };
  background = config.background or { };
  terminal = config.terminal or "ghostty";
  viewport = config.viewport or { };

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
    "SUPER + Q" = terminal;
    "SUPER + E" = config.fileManager or "dolphin";
    "SUPER + Space" = config.launcher or "fuzzel";
    "SUPER + R" = config.launcher or "fuzzel";
    "SUPER + L" = "breakland-shell --lock";
  } (config.keybindings or { });

  dispatcherBindings = lib.recursiveUpdate {
    "SUPER + C" = "hl.dsp.window.close()";
    "SUPER + V" = "hl.dsp.window.float({ action = \"toggle\" })";
    "SUPER + P" = "hl.dsp.window.pseudo()";
    "SUPER + M" = "hl.dsp.exit()";
    "SUPER + Left" = "hl.dsp.focus({ direction = \"left\" })";
    "SUPER + Right" = "hl.dsp.focus({ direction = \"right\" })";
    "SUPER + Up" = "hl.dsp.focus({ direction = \"up\" })";
    "SUPER + Down" = "hl.dsp.focus({ direction = \"down\" })";
    "SUPER + mouse_down" = "hl.dsp.focus({ workspace = \"e+1\" })";
    "SUPER + mouse_up" = "hl.dsp.focus({ workspace = \"e-1\" })";
    "SUPER + mouse:272" = "hl.dsp.window.drag(), { mouse = true }";
    "SUPER + mouse:273" = "hl.dsp.window.resize(), { mouse = true }";
  } (config.dispatchers or { });

  workspaceBindings = lib.listToAttrs (
    map (entry: {
      name = "SUPER + ${entry.key}";
      value = "hl.dsp.focus({ workspace = \"${entry.workspace}\" })";
    }) [
      { key = "1"; workspace = "1"; }
      { key = "2"; workspace = "2"; }
      { key = "3"; workspace = "3"; }
      { key = "4"; workspace = "4"; }
      { key = "5"; workspace = "5"; }
      { key = "6"; workspace = "6"; }
      { key = "7"; workspace = "7"; }
      { key = "8"; workspace = "8"; }
      { key = "9"; workspace = "9"; }
      { key = "0"; workspace = "10"; }
    ]
  );

  moveWorkspaceBindings = lib.listToAttrs (
    map (entry: {
      name = "SUPER + SHIFT + ${entry.key}";
      value = "hl.dsp.window.move({ workspace = \"${entry.workspace}\" })";
    }) [
      { key = "1"; workspace = "1"; }
      { key = "2"; workspace = "2"; }
      { key = "3"; workspace = "3"; }
      { key = "4"; workspace = "4"; }
      { key = "5"; workspace = "5"; }
      { key = "6"; workspace = "6"; }
      { key = "7"; workspace = "7"; }
      { key = "8"; workspace = "8"; }
      { key = "9"; workspace = "9"; }
      { key = "0"; workspace = "10"; }
    ]
  );

  viewportLua = if viewport.enable or false then ''
    local breaklandViewportPosition = 1
    local breaklandViewportLeft = ${builtins.toJSON (viewport.leftMonitor or "DP-1")}
    local breaklandViewportRight = ${builtins.toJSON (viewport.rightMonitor or "DP-2")}
    local breaklandViewportMaximum = ${toString (viewport.maxPosition or 5)}

    local function breaklandViewportMove(direction)
      if direction == "right" then
        if breaklandViewportPosition >= breaklandViewportMaximum then return end
        breaklandViewportPosition = breaklandViewportPosition + 1
      elseif direction == "left" then
        if breaklandViewportPosition <= 1 then return end
        breaklandViewportPosition = breaklandViewportPosition - 1
      else
        return
      end

      local leftWorkspace = tostring(breaklandViewportPosition)
      local rightWorkspace = tostring(breaklandViewportPosition + 1)

      hl.dispatch(hl.dsp.workspace.move({ workspace = rightWorkspace, monitor = breaklandViewportRight }))
      hl.dispatch(hl.dsp.workspace.move({ workspace = leftWorkspace, monitor = breaklandViewportLeft }))
      hl.dispatch(hl.dsp.focus({ monitor = breaklandViewportRight }))
      hl.dispatch(hl.dsp.focus({ workspace = rightWorkspace }))
      hl.dispatch(hl.dsp.focus({ monitor = breaklandViewportLeft }))
      hl.dispatch(hl.dsp.focus({ workspace = leftWorkspace }))

      for workspace = 1, breaklandViewportMaximum + 1 do
        local currentWorkspace = tostring(workspace)
        if currentWorkspace ~= leftWorkspace and currentWorkspace ~= rightWorkspace then
          hl.dispatch(hl.dsp.workspace.move({ workspace = currentWorkspace, monitor = breaklandViewportLeft }))
        end
      end
    end

    hl.bind("SUPER + CTRL + Right", function() breaklandViewportMove("right") end)
    hl.bind("SUPER + CTRL + Left", function() breaklandViewportMove("left") end)
  '' else "";
in
selflib.toBreaklandLua {
  inherit settings keybindings;
  dispatcherBindings = dispatcherBindings // workspaceBindings // moveWorkspaceBindings;
  extraConfig = viewportLua;
}
