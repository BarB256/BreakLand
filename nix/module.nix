inputs:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
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

      font = lib.mkOption {
        type = with lib.types; attrsOf (oneOf [ str int ]);
        default = {
          family = "Sans";
          size = 11;
        };
        description = "Default BreakLand and shell font settings.";
      };

      background = lib.mkOption {
        type = with lib.types; attrsOf str;
        default = { color = "0xff000000"; };
        description = "Default BreakLand background settings.";
      };

      terminal = lib.mkOption {
        type = lib.types.str;
        default = "ghostty";
        description = "Terminal command used by the default keybindings.";
      };

      launcher = lib.mkOption {
        type = lib.types.str;
        default = "fuzzel";
        description = "Application launcher command used by the default keybindings.";
      };

      fileManager = lib.mkOption {
        type = lib.types.str;
        default = "dolphin";
        description = "File manager command used by the default keybindings.";
      };

      keybindings = lib.mkOption {
        type = with lib.types; attrsOf str;
        default = { };
        description = "Keybindings mapping a key chord to an executable command.";
      };

      dispatchers = lib.mkOption {
        type = with lib.types; attrsOf str;
        default = { };
        description = "Keybindings mapping a key chord to a BreakLand dispatcher expression.";
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

      environment.etc."xdg/breakland/config.nix" = {
        text = builtins.toJSON {
          compositor = cfg.settings;
          font = cfg.font;
          background = cfg.background;
          terminal = cfg.terminal;
          launcher = cfg.launcher;
          fileManager = cfg.fileManager;
          keybindings = cfg.keybindings;
          dispatchers = cfg.dispatchers;
        };
      };
    })
  ];
}
