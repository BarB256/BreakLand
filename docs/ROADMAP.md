# BreakLand Roadmap

BreakLand is not version 1 yet. Reproducibility across old configuration versions is
not a current requirement; the configuration model will be allowed to change while
the basic desktop is being built.

## Current Foundation

- Basic Wayland compositor build and Nix package
- Native plugin infrastructure removed
- BreakLand-specific executable, launcher, control utility, sessions, and Nix outputs
- Black default background with inherited wallpaper and splash presentation disabled
- Quickshell-based shell package with a minimal panel and background surface

## First Desktop Milestone

- Nix-generated BreakLand Lua configuration
- Basic tiling defaults and floating dialog behavior
- System font selection
- Terminal, launcher, and close-window keybindings
- Black background by default
- Quickshell shell started with the session
- Per-monitor panel and workspace indicators
- Clock and basic session controls
- Basic application launcher integration

## Window Management

- Stable basic tiling workflow
- Focus and movement in cardinal directions
- Window resizing and floating dialogs
- Fullscreen and maximize behavior
- Workspace switching and moving windows between workspaces
- Scrolling layout as a primary BreakLand workflow
- Simple, conservative animations

## QML Desktop Shell

- Panel and workspace state
- Application launcher
- Notification center
- System tray
- Audio and network status controls
- Display arrangement and mirroring controls
- Wallpaper selection and per-monitor wallpaper policy
- Session lock, logout, restart, and shutdown controls
- Reconnection after compositor restart

## Display Management

- Monitor discovery and state display
- Extend and mirror operations
- Position, scale, transform, and mode selection
- Apply, confirm, and revert transactions
- Safe rollback when an output configuration fails
- Hotplug handling

## Configuration

- Typed NixOS and Home Manager options
- Generated compositor configuration
- Generated shell settings
- Explicit validation and useful error messages
- Runtime-only settings changes from the shell during development
- Later: versioned configuration migrations and reproducibility guarantees

## Scope Boundaries

- No Hyprland plugin compatibility
- No inherited plugin manager
- No Waybar dependency
- No default wallpaper or promotional startup UI
- Qt/QML remains outside the compositor process
