{
  lib,
  stdenvNoCC,
  quickshell,
  writeShellScript,
}:
let
  launcher = writeShellScript "breakland-shell" ''
    RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/tmp}"
    if [ -z "''${BREAKLAND_INSTANCE_SIGNATURE:-}" ]; then
      LOCK_FILE=$(find "$RUNTIME_DIR/breakland" -name breakland.lock -type f -print -quit 2>/dev/null || true)
      if [ -n "$LOCK_FILE" ]; then
        export BREAKLAND_INSTANCE_SIGNATURE=$(basename "$(dirname "$LOCK_FILE")")
        export WAYLAND_DISPLAY=$(sed -n '2p' "$LOCK_FILE")
      fi
    fi

    if [ "$1" = "--lock" ]; then
      shift
      exec ${quickshell}/bin/quickshell ipc call breakland lock "$@"
    fi

    exec ${quickshell}/bin/quickshell -p "@BREAKLAND_SHELL_ROOT@" "$@"
  '';
in
stdenvNoCC.mkDerivation {
  pname = "breakland-shell";
  version = "0.1.0";
  src = ../shell;

  installPhase = ''
    mkdir -p $out/share/breakland-shell
    mkdir -p $out/bin
    cp -r ./* $out/share/breakland-shell/
    install -Dm644 ${../skull.txt} $out/share/breakland-shell/skull.txt

    substitute ${launcher} $out/bin/breakland-shell \
      --replace-fail @BREAKLAND_SHELL_ROOT@ $out/share/breakland-shell
    chmod 755 $out/bin/breakland-shell
  '';

  meta = {
    description = "Quickshell desktop shell for BreakLand";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "breakland-shell";
  };
}
