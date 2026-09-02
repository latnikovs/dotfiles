#!/usr/bin/env bash
# Publishes what Claude Code is doing into the tmux window chip.
#
# Called from the Claude Code hooks in ~/.claude/settings.json, one invocation
# per event, with the state as $1:
#
#   busy   a turn is running        (UserPromptSubmit, Pre/PostToolUse)
#   wait   it wants something       (Notification: a permission prompt, idle nag)
#   idle   the turn finished        (Stop, SessionStart)
#   clear  no Claude here any more  (SessionEnd)
#
# The state is written as a *pane* option on the pane the hook ran in, which is
# what makes this cost nothing to display: tmux resolves #{@claude_state} in
# window-status-format against that window's active pane, so the chips read the
# value directly on redraw. No #() job, no polling, no state files to reap --
# the option dies with the pane.
#
# Hooks run in the Claude process's environment, so $TMUX_PANE is the pane it
# was started in even when the hook fires from a deeply nested shell.
#
# Every path exits 0: a hook that fails is reported to Claude as an error, and a
# status bar decoration is never worth interrupting a turn over.
set -u

state="${1:-}"

# Claude feeds the hook its event JSON on stdin. Drain it even when unused, so
# it never sees a closed pipe, and so the subagent check below has it.
input=""
if [ ! -t 0 ]; then
	input="$(cat 2>/dev/null || true)"
fi

# Subagent turns start and stop inside the main one. Letting them drive the
# chip would flip it to idle while the parent is still working.
case "$input" in
*'"agent_id"'*)
	case "$input" in
	*'"agent_id": null'* | *'"agent_id":null'*) ;;
	*) exit 0 ;;
	esac
	;;
esac

[ -n "${TMUX:-}" ] || exit 0
[ -n "${TMUX_PANE:-}" ] || exit 0
command -v tmux >/dev/null 2>&1 || exit 0

case "$state" in
busy | wait | idle)
	tmux set-option -p -t "$TMUX_PANE" @claude_state "$state" 2>/dev/null || exit 0
	;;
clear)
	tmux set-option -p -u -t "$TMUX_PANE" @claude_state 2>/dev/null || exit 0
	;;
*)
	exit 0
	;;
esac

# status-interval is 5s; without this the chip would lag a turn ending by up to
# that long, which is exactly the moment the indicator exists for.
#
# Every client, not just this pane's: the agents pill in status-left reports on
# *other* sessions, so a state change here is news to every other kitty tab's
# status line. refresh-client with no -t only reaches the client tmux infers
# from this command's context, which leaves the tabs that actually needed
# telling waiting for their next tick.
tmux list-clients -F '#{client_name}' 2>/dev/null | while IFS= read -r client; do
	[ -n "$client" ] || continue
	tmux refresh-client -S -t "$client" 2>/dev/null || true
done
exit 0
