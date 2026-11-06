inputs:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
  selflib = import ./lib.nix lib;
  cfg = config.programs.breakland;
in
{
  options = {
    programs.breakland = {
      enable = lib.mkEnableOption "BreakLand";

      package = lib.mkOption {
        type = lib.types.package;
        default = inputs.self.packages.${system}.breakland;
        description = "The BreakLand package to install.";
      };

      portalPackage = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = inputs.self.packages.${system}.xdg-desktop-portal-breakland;
        description = "The BreakLand desktop portal package.";
      };

      shell = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to install the BreakLand Quickshell desktop shell.";
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = inputs.self.packages.${system}.breakland-shell;
          description = "The BreakLand Quickshell package.";
        };
      };

      settings = lib.mkOption {
          type =
          with lib.types;
          let
            valueType =
              nullOr (oneOf [
                bool
                int
                float
                str
                path
                (attrsOf valueType)
                (listOf valueType)
              ])
              // {
          description = "BreakLand configuration value";
              };
          in
          valueType;
        default = { };
        description = ''
          BreakLand compositor settings written in Nix. Nested attribute sets
          become Lua tables and lists become Lua arrays.

        '';
        example = lib.literalExpression ''
          {
            decoration = {
              shadow_offset = "0 5";
              "col.shadow" = "rgba(00000099)";
            };

            "$mod" = "SUPER";

            bindm = [
              # mouse movements
              "$mod, mouse:272, movewindow"
              "$mod, mouse:273, resizewindow"
              "$mod ALT, mouse:272, resizewindow"
            ];
          }
        '';
      };

      extraConfig = lib.mkOption {
        type = lib.types.lines;
        default = "";
        example = ''
          # window resize
          bind = $mod, S, submap, resize

          submap = resize
          binde = , right, resizeactive, 10 0
          binde = , left, resizeactive, -10 0
          binde = , up, resizeactive, 0 -10
          binde = , down, resizeactive, 0 10
          bind = , escape, submap, reset
          submap = reset
        '';
        description = ''
          Extra Lua configuration lines appended to the generated config.
        '';
      };

    };
  };
  config = lib.mkMerge [
    {
      programs.breakland = {
        package = lib.mkDefault inputs.self.packages.${system}.breakland;
        portalPackage = lib.mkDefault inputs.self.packages.${system}.xdg-desktop-portal-breakland;
      };
    }
    (lib.mkIf cfg.enable {
      # Allows BreakLand assets to be accessed from the system profile.
      environment.pathsToLink = [ "/share/breakland" ];

      environment.systemPackages = [ cfg.package ] ++ lib.optional cfg.shell.enable cfg.shell.package;

      systemd.user.services.breakland-shell = lib.mkIf cfg.shell.enable {
        description = "BreakLand Quickshell desktop shell";
        wantedBy = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${cfg.shell.package}/bin/breakland-shell";
          Restart = "on-failure";
          RestartSec = 2;
        };
      };

      environment.etc."xdg/breakland/breakland.lua" = {
        text = selflib.toBreaklandLua {
          settings = lib.recursiveUpdate {
            general = {
              gaps_in = 5;
              gaps_out = 20;
              border_size = 2;
              layout = "dwindle";
            };
            misc = {
              disable_hyprland_logo = true;
              disable_splash_rendering = true;
              background_color = 4278190080;
              font_family = "Sans";
            };
            input = {
              kb_layout = "us";
            };
          } cfg.settings;
          keybindings = {
            "SUPER + Return" = "foot";
            "SUPER + Space" = "fuzzel";
          };
          extraConfig = cfg.extraConfig;
        };
      };
    })
  ];
}
