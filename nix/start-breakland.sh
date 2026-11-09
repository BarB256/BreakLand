#!/bin/sh
set -eu

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/breakland"
CONFIG="$CONFIG_DIR/config.nix"
GENERATOR="@BREAKLAND_GENERATOR@"
DEFAULT_CONFIG="@BREAKLAND_DEFAULT_CONFIG@"
START_BREAKLAND="@START_BREAKLAND_BIN@"
export PATH="@BREAKLAND_RUNTIME_PATH@:$PATH"

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

if [ ! -e "$CONFIG" ] || grep -q "BreakLand configuration is written in Nix" "$CONFIG" 2>/dev/null; then
    mkdir -p "$CONFIG_DIR"
    cp "$DEFAULT_CONFIG" "$CONFIG"
fi

RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
LUA_CONFIG="$RUNTIME_DIR/breakland-config-$$.lua"
trap 'rm -f "$LUA_CONFIG"' EXIT INT TERM

BREAKLAND_CONFIG_PATH="$CONFIG" \
BREAKLAND_GENERATOR_PATH="$GENERATOR" \
nix eval \
    --impure \
    --extra-experimental-features 'nix-command flakes' \
    --raw \
    --expr 'let
      configPath = builtins.getEnv "BREAKLAND_CONFIG_PATH";
      generatorPath = builtins.getEnv "BREAKLAND_GENERATOR_PATH";
      lib = (builtins.getFlake "nixpkgs").lib;
      config = import (/. + configPath);
    in import (/. + generatorPath) { inherit lib config; }' \
    > "$LUA_CONFIG"

exec "$START_BREAKLAND" -- --config "$LUA_CONFIG" "$@"
