#!/usr/bin/env bash
# Launches or resumes a Claude Code session directly on the Home Assistant
# host itself (the "Advanced SSH & Web Terminal" add-on container, not this
# repo's own ESPHome devcontainer), as a window in whatever tmux session is
# already there (one window per agent) - so it never interferes with other
# sessions a human might have running, and joins whatever's already in use
# instead of sprawling into one top-level tmux session per agent. Remote
# Control is enabled, so a human or this agent can start one without tying
# up an SSH connection, and reconnect later from claude.ai/code or the
# Claude app.
#
# Mirrors vm-configs' scripts/claude-worktree.sh convention (name-based
# subcommands), adapted for a single remote host with no per-session
# worktree - every session here shares the one checkout at $WORKDIR.
#
# Claude Code is already installed on the host under /data/npm-global (see
# /etc/profile.d/npm-global.sh), persisted there so it survives add-on
# updates; it's only on PATH for root's actual login shell (zsh), not a bare
# non-interactive `ssh host cmd`. tmux starts panes with that same login
# shell by default, so launching the real `claude` command through a tmux
# pane (rather than inline in an `ssh host "claude ..."` call) picks it up
# correctly without this script needing to know where it lives.
set -euo pipefail

HOST="homeassistant"
WORKDIR="/config"
READY_TIMEOUT=15
# Session name to bootstrap with if nothing is running yet. Only matters the
# very first time - after that, whatever's already there wins (see below).
DEFAULT_SESSION="main"

usage() {
    cat <<'EOF'
Usage:
  scripts/claude-ha-session.sh new <name>      Start a new Claude session named <name> as a new
                                                 window in whatever tmux session already exists on
                                                 the Home Assistant host (creating one if none does),
                                                 with Remote Control enabled.
  scripts/claude-ha-session.sh resume <name>   Resume the Claude session named <name>. If its window
                                                 is still around but idle, resumes in place; if the
                                                 window's gone, recreates one the same way `new` would
                                                 and resumes there instead.

Connect from claude.ai/code or the Claude app once it reports ready.
EOF
    exit 1
}

[ $# -ge 2 ] || usage
cmd="$1"
name="$2"

case "$name" in
*"'"*)
    echo "error: session name can't contain a single quote: $name" >&2
    exit 1
    ;;
esac

window_name="${name// /_}"

# Only ever at most one tmux session is expected on this host (nothing here
# uses named sessions - everything is started with plain `tmux`), so this
# returns a single name or nothing, never a list to disambiguate.
remote_current_session() {
    ssh -o BatchMode=yes "$HOST" bash -s <<'EOF'
tmux list-sessions -F '#{session_name}' 2>/dev/null | head -n1
EOF
}

# Lists window names in a given session - takes the session explicitly
# (rather than reading a global) since it's called both before and after
# $target_session is settled (`resume` checks the current session first,
# `new` checks only after select_target_session has run).
remote_list_windows_in() {
    local session="$1"
    ssh -o BatchMode=yes "$HOST" bash -s <<EOF
tmux list-windows -t "$session" -F '#{window_name}' 2>/dev/null
EOF
}

remote_kill_window() {
    ssh -o BatchMode=yes "$HOST" bash -s <<EOF
tmux kill-window -t "$target_session:$window_name" 2>/dev/null || true
EOF
}

remote_capture_pane() {
    ssh -o BatchMode=yes "$HOST" bash -s <<EOF
tmux capture-pane -p -t "$target_session:$window_name" 2>/dev/null
EOF
}

# Picks which tmux session a new window should land in: joins the one
# session that already exists (whatever it's named - never created by this
# script, typically tmux's own default), or bootstraps $DEFAULT_SESSION if
# none does. Sets the global $target_session/$create_session.
select_target_session() {
    local session
    session="$(remote_current_session)"
    if [ -n "$session" ]; then
        target_session="$session"
        create_session=false
    else
        target_session="$DEFAULT_SESSION"
        create_session=true
    fi
}

# Creates $window_name in $target_session, creating the session first if
# $create_session is true. Shared by `new` and `resume`'s recreate path.
create_window() {
    if [ "$create_session" = true ]; then
        echo "No tmux session exists on $HOST yet - creating '$target_session'."
        # -d: detached from the start, no attach/detach dance needed. -n
        # names the initial window directly. -c: new pane's starting
        # directory - tmux's default-shell behavior (root's login shell)
        # takes care of PATH/env setup from there, see header.
        ssh -o BatchMode=yes "$HOST" bash -s <<EOF
set -e
tmux new-session -d -s "$target_session" -n "$window_name" -c "$WORKDIR"
EOF
    else
        echo "Joining existing tmux session '$target_session' on $HOST as a new window."
        ssh -o BatchMode=yes "$HOST" bash -s <<EOF
set -e
tmux new-window -t "$target_session" -n "$window_name" -c "$WORKDIR"
EOF
    fi
}

send_claude_command() {
    local claude_args="$1"
    ssh -o BatchMode=yes "$HOST" bash -s <<EOF
set -e
tmux send-keys -t "$target_session:$window_name" "claude $claude_args" Enter
EOF
}

# Polls the pane until Claude reaches a normal ready state, rather than
# assuming success. Bails out (and kills just this window, never the whole
# session - other agents' windows may be sharing it) if it's stuck on
# something that needs a human - a workspace trust dialog, a login/auth
# prompt - instead of leaving a half-started window behind silently.
wait_for_ready() {
    local i pane
    for i in $(seq 1 "$READY_TIMEOUT"); do
        sleep 1
        pane="$(remote_capture_pane)"
        if grep -qiE 'do you trust|trust the files in this folder|/login|not authenticated|please (log|sign) in|invalid api key' <<<"$pane"; then
            echo "error: Claude is waiting on an unexpected prompt (trust/login/auth) - aborting and killing the window. Pane contents:" >&2
            echo "$pane" >&2
            remote_kill_window
            exit 1
        fi
        if grep -qiE 'auto mode on|remote.control' <<<"$pane"; then
            echo "Ready. Session '$name' is live in window '$window_name' of tmux session '$target_session' on $HOST, Remote Control enabled."
            return 0
        fi
    done
    echo "error: timed out after ${READY_TIMEOUT}s waiting for a ready state - inspect manually:" >&2
    echo "  ssh $HOST tmux attach -t $target_session" >&2
    exit 1
}

case "$cmd" in
new)
    select_target_session
    if [ "$create_session" = false ]; then
        mapfile -t windows < <(remote_list_windows_in "$target_session")
        for w in "${windows[@]}"; do
            if [ "$w" = "$window_name" ]; then
                echo "error: window '$window_name' already exists in tmux session '$target_session' on $HOST - choose a different name" >&2
                exit 1
            fi
        done
    fi

    create_window
    send_claude_command "-n '$name' --remote-control '$name'"

    echo "Waiting for Claude to reach a ready state..."
    wait_for_ready
    ;;
resume)
    # Resuming is for the common case where the previous tmux session/window
    # has already ended entirely (e.g. a host reboot killed tmux) - it
    # doesn't try to reach into a window that's still around. If one with
    # this name already exists (in the one session there can be), fail
    # rather than guess what state it's in; attach directly instead if it's
    # still running.
    session="$(remote_current_session)"
    if [ -n "$session" ]; then
        mapfile -t windows < <(remote_list_windows_in "$session")
        for w in "${windows[@]}"; do
            if [ "$w" = "$window_name" ]; then
                echo "error: window '$window_name' already exists in tmux session '$session' on $HOST - if it's still running, attach directly instead:" >&2
                echo "  ssh $HOST tmux attach -t $session" >&2
                exit 1
            fi
        done
    fi

    echo "No existing window named '$window_name' found on $HOST - recreating it."
    select_target_session
    create_window
    send_claude_command "--resume '$name' --remote-control '$name'"

    echo "Waiting for Claude to reach a ready state..."
    wait_for_ready
    ;;
*)
    usage
    ;;
esac
