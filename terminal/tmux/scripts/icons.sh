#!/usr/bin/env bash
# Publishes the glyphs tmux.conf needs as tmux options, so the config file can
# stay plain ASCII and refer to them as #{@ico_*} / #{@cap_*}.
#
# tmux config has no \u escape, so the alternative is pasting private-use
# codepoints straight into tmux.conf, where they are invisible to read and easy
# for tooling to silently drop. Sourcing lib.sh also keeps one definition of the
# pill caps shared between the config and the module scripts.
set -u

# shellcheck source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

tmux set -g @cap_l "$CAP_L"
tmux set -g @cap_r "$CAP_R"

tmux set -g @ico_session $'\U000f018d'  # md-console
tmux set -g @ico_prefix $'\U000f030c'   # md-keyboard
tmux set -g @ico_zoom $'\U000f0293'     # md-fullscreen
tmux set -g @ico_clock $'\U000f0150'    # md-clock

# Window icons, keyed off #{pane_current_command} by the @win_icon map.
tmux set -g @ico_vim $'\U000f085e'      # md-vim
tmux set -g @ico_git $'\U000f02a2'      # md-git
tmux set -g @ico_go $'\U000f07d3'       # md-language-go
tmux set -g @ico_node $'\U000f0399'     # md-nodejs
tmux set -g @ico_python $'\U000f0320'   # md-language-python
tmux set -g @ico_docker $'\U000f0868'   # md-docker
tmux set -g @ico_ssh $'\U000f0318'      # md-lan-connect
tmux set -g @ico_folder $'\U000f024b'   # md-folder
tmux set -g @ico_java $'\U000f0176'     # md-coffee
tmux set -g @ico_shell $'\U000f018d'    # md-console
tmux set -g @ico_default $'\U000f0349'  # md-magnify
