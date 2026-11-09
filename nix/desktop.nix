{
  lib,
  stdenvNoCC,
  writeShellScript,
  breakland,
  breakland-shell,
}:
let
  launcher = writeShellScript "breakland-desktop" ''
    set -eu

    RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/tmp}"
    LOCK_FILE=""
    SHELL_PID=""
    export PATH="${breakland-shell}/bin:${breakland}/bin:$PATH"

    cleanup() {
      if [ -n "$SHELL_PID" ]; then
        kill "$SHELL_PID" 2>/dev/null || true
      fi
    }
    trap cleanup EXIT INT TERM

    ${breakland}/bin/start-breakland "$@" &
    COMPOSITOR_PID=$!

    for _ in $(seq 1 100); do
      LOCK_FILE=$(find "$RUNTIME_DIR/breakland" -name breakland.lock -type f -print -quit 2>/dev/null || true)
      if [ -n "$LOCK_FILE" ]; then
        break
      fi
      if ! kill -0 "$COMPOSITOR_PID" 2>/dev/null; then
        wait "$COMPOSITOR_PID"
        exit $?
      fi
      sleep 0.1
    done

    if [ -z "$LOCK_FILE" ]; then
      echo "BreakLand did not create its session lock file" >&2
      exit 1
    fi

    WAYLAND_DISPLAY=$(sed -n '2p' "$LOCK_FILE")
    BREAKLAND_INSTANCE_SIGNATURE=$(basename "$(dirname "$LOCK_FILE")")
    export WAYLAND_DISPLAY
    export BREAKLAND_INSTANCE_SIGNATURE

    SHELL_LOG="$RUNTIME_DIR/breakland-shell.log"
    ${breakland-shell}/bin/breakland-shell >"$SHELL_LOG" 2>&1 &
    SHELL_PID=$!

    wait "$COMPOSITOR_PID"
  '';
in
stdenvNoCC.mkDerivation {
  pname = "breakland-desktop";
  version = "0.1.0";
  dontUnpack = true;

  installPhase = ''
    install -Dm755 ${launcher} $out/bin/breakland-desktop
  '';

  meta = {
    description = "BreakLand compositor and Quickshell desktop session";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "breakland-desktop";
  };
}
