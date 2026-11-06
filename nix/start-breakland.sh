#!/bin/sh
set -eu

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/breakland"
CONFIG="$CONFIG_DIR/config.nix"
GENERATOR="@BREAKLAND_GENERATOR@"
START_BREAKLAND="@START_BREAKLAND_BIN@"

if [ ! -e "$CONFIG" ]; then
    OLD_IFS="$IFS"
    IFS=:
    for dir in ${XDG_CONFIG_DIRS:-/etc/xdg}; do
        if [ -e "$dir/breakland/config.nix" ]; then
            CONFIG="$dir/breakland/config.nix"
            break
        fi
    done
    IFS="$OLD_IFS"
fi

if [ ! -e "$CONFIG" ]; then
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG" <<'EOF'
{
  # BreakLand configuration is written in Nix.
  # Add compositor, font, background, terminal, launcher, and keybindings here.
}
EOF
fi

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
LUA_CONFIG="$RUNTIME_DIR/breakland-config-$$.lua"
trap 'rm -f "$LUA_CONFIG"' EXIT INT TERM

nix eval \
    --impure \
    --extra-experimental-features 'nix-command flakes' \
    --raw \
    --argstr configPath "$CONFIG" \
    --argstr generatorPath "$GENERATOR" \
    --expr 'let
      lib = (builtins.getFlake "nixpkgs").lib;
      config = import (/. + configPath);
    in import (/. + generatorPath) { inherit lib config; }' \
    > "$LUA_CONFIG"

exec "$START_BREAKLAND" -- --config "$LUA_CONFIG" "$@"
