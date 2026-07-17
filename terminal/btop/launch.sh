#!/usr/bin/env bash
# Launch btop with the theme directory matching the current OS appearance.
#
# btop reads color_theme once at startup and has no light/dark switching of its
# own, so the flavor has to be chosen before it starts. Both flavors ship a
# theme named "catppuccin" — the name btop.conf asks for — in a directory of
# their own, so picking the directory picks the flavor without touching the
# config. That keeps btop.conf a static file: btop rewrites its config whenever
# a setting changes in the TUI, and a config this script edited on every launch
# would fight that.
#
# This exists as a script rather than a shell function because tmux's
# display-popup runs its command through sh, which never sources an interactive
# shell — a function would simply not exist there, and btop would quietly fall
# back to its default theme. One script, both callers.
#
# flavor.sh lives under ~/.tmux only because tmux needed it first; it is a plain
# 'what is the OS appearance' probe with no tmux dependency. If it is missing,
# btop still starts, just with whatever theme its config names.
set -u

flavor="$("$HOME/.tmux/scripts/flavor.sh" 2>/dev/null || true)"
dir="$HOME/.config/btop/themes-${flavor}"

if [ -n "$flavor" ] && [ -d "$dir" ]; then
	exec btop --themes-dir "$dir" "$@"
fi

exec btop "$@"
