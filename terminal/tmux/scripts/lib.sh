#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034  # every constant here is used by the modules that source it.
# Shared helpers for the tmux status modules.
#
# tmux runs each #(command) as a job and parses #[...] style sequences out of
# its output, but it does not re-expand #{...} there. So a module receives its
# colors as arguments (tmux expands #{@thm_*} before exec) and prints its own
# styling. A module that has nothing to say prints nothing, and its pill
# disappears from the bar entirely.
#
# Every glyph below is written as a \u escape rather than pasted in literally.
# They are private-use codepoints: they carry no meaning outside a patched font,
# they are invisible in most diffs and editors, and tooling that touches this
# file can silently drop them, which leaves the bar rendering blank gaps. The
# escape says exactly which glyph is meant and cannot be mangled. Every
# codepoint here is present in JetBrainsMono Nerd Font.

# Rounded pill caps (Powerline).
readonly CAP_L=$'\ue0b6'          # powerline left half circle
readonly CAP_R=$'\ue0b4'          # powerline right half circle

# Material Design icons, all above U+FFFF.
readonly ICO_BRANCH=$'\U000f062c'   # md-source-branch
readonly ICO_CONFLICT=$'\U000f0028' # md-alert-circle
readonly ICO_CPU=$'\U000f0ee0'      # md-cpu-64-bit
readonly ICO_MEM=$'\U000f035b'      # md-memory
readonly ICO_WIFI=$'\U000f05a9'     # md-wifi
readonly ICO_WIFI_OFF=$'\U000f05aa' # md-wifi-off

# Escape text that tmux will parse as a format: '#' is the escape character,
# so a branch named 'feat/#12' has to arrive as 'feat/##12'.
esc() {
	printf '%s' "${1//#/##}"
}

# pill <surface> <accent> <text>
# Rounded pill: caps drawn in the surface color over the terminal background,
# text in the accent color over the surface fill.
pill() {
	local surface="$1" accent="$2" text="$3"
	printf '#[fg=%s,bg=default]%s#[fg=%s,bg=%s,bold] %s #[fg=%s,bg=default,nobold]%s' \
		"$surface" "$CAP_L" "$accent" "$surface" "$text" "$surface" "$CAP_R"
}
