#!/usr/bin/env bash
# Single tmux job that renders the whole right-hand side of the status bar.
# Usage: status.sh <path> <surface> <green> <peach> <sapphire> <mauve> \
#                  <yellow> <red> <teal>
#
# Why this exists rather than four #() jobs, one per module:
#
# tmux runs every #() as its own job and redraws the status line each time one
# of them finishes. The modules take 50-95ms apiece and never finish together,
# so four jobs meant the bar repainted four times in a row every
# status-interval. Each repaint is a different width (a module's pill grows and
# shrinks with its value), and status-justify is 'centre', which measures the
# window list against whatever sits beside it — so the window list visibly
# jumped on each of those four paints. One job means one width change and one
# redraw: the bar updates atomically.
#
# The modules stay separate executables, and still run standalone; this only
# collapses them into a single job. They run in sequence (~270ms total, once
# per interval), which is well inside the interval and keeps output ordered.
set -u

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

path="${1:?path required}"
surface="${2:?surface required}"
green="${3:?green required}"
peach="${4:?peach required}"
sapphire="${5:?sapphire required}"
mauve="${6:?mauve required}"
yellow="${7:?yellow required}"
red="${8:?red required}"
teal="${9:?teal required}"

# What pill() colours a label with, or empty to mean 'use the accent'. Decided
# per flavor by palette.sh, and exported rather than threaded through every
# module's argument list: it is the same answer for every pill on the bar, and
# the modules never need to reason about it.
export PILL_TEXT="${10:-}"

out=''
append() {
	local text
	text="$("$@")" || return 0
	[ -n "$text" ] || return 0
	# A module that prints nothing owns no space, so the separator belongs to
	# whatever actually rendered.
	out+="$text "
}

append "$dir/git.sh" "$path" "$surface" "$green" "$peach"
append "$dir/sys.sh" "$surface" "$sapphire" "$mauve" "$peach"
append "$dir/battery.sh" "$surface" "$green" "$yellow" "$red"
append "$dir/online.sh" "$surface" "$teal" "$red"

# One write: tmux parses the job's output as a whole, so the bar never renders
# a half-assembled right side.
printf '%s' "$out"
