#!/usr/bin/env bash
# Launches or resumes a Claude Code session inside the ESPHome docker
# container on frigate-srv3 (where the `esphome` CLI actually lives - see
# AGENTS.md "Docker Container"), as a window in whatever tmux session is
# already there (one window per agent) - so it never interferes with other
# sessions a human might have running, and joins whatever's already in use
# instead of sprawling into one top-level tmux session per agent. Remote
# Control is enabled, so a human or this agent can start one without tying
# up an SSH connection, and reconnect later from claude.ai/code or the
# Claude app.
#
# Near-identical sibling of home-assistant-config's own scripts/claude-ha-
# session.sh (master branch) - same shape (name-based new/resume
# subcommands, join-one-shared-tmux-session, poll-for-ready rather than
# assume success), just pointed at a different host. Deliberately a
# separate script rather than one parameterized for both: this repo keeps
# HA and ESPHome concerns on separate branches anyway (see AGENTS.md) -
# duplicating ~150 lines reads easier than threading host differences
# through shared parameters.
#
# `claude` is already on PATH for a bare non-interactive `ssh host cmd`
# here (confirmed - no shell-profile-sourcing gotcha like the HA host's
# zsh-only PATH setup), so no special launch handling needed beyond what
# tmux already gives us.
set -euo pipefail

# "esphome" is an alias in ~/.ssh/config (frigate-srv3, port 2222, user abc)
# - use that rather than hardcoding the host/port/user here, so this script
# and a human typing `ssh esphome` by hand always mean the same place.
SSH_HOST="esphome"
WORKDIR="/config"
READY_TIMEOUT=15
# Session name to bootstrap with if nothing is running yet. Only matters the
# very first time - after that, whatever's already there wins (see below).
DEFAULT_SESSION="main"

usage() {
    cat <<'EOF'
Usage:
  scripts/claude-esphome-session.sh new <name>      Start a new Claude session named <name> as a
                                                       new window in whatever tmux session already
                                                       exists in the ESPHome container on
                                                       frigate-srv3 (creating one if none does),
                                                       with Remote Control enabled.
  scripts/claude-esphome-session.sh resume <name>   Resume the Claude session named <name>. If its
                                                       window is still around but idle, resumes in
                                                       place; if the window's gone, recreates one
                                                       the same way `new` would and resumes there
                                                       instead.

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

# Only ever at most one tmux session is expected in this container (nothing
# here uses named sessions - everything is started with plain `tmux`), so
# this returns a single name or nothing, never a list to disambiguate.
remote_current_session() {
    ssh -o BatchMode=yes "$SSH_HOST" bash -s <<'EOF'
tmux list-sessions -F '#{session_name}' 2>/dev/null | head -n1
EOF
}

# Lists window names in a given session - takes the session explicitly
# (rather than reading a global) since it's called both before and after
# $target_session is settled (`resume` checks the current session first,
# `new` checks only after select_target_session has run).
remote_list_windows_in() {
    local session="$1"
    # Trailing colon forces session-name interpretation - without it, a
    # session literally named a bare number (tmux's own default auto-name,
    # e.g. "0", which is exactly what this container's session was already
    # named the first time this was tried by hand) gets parsed as a window
    # index instead and fails ("create window failed: index 0 in use").
    ssh -o BatchMode=yes "$SSH_HOST" bash -s <<EOF
tmux list-windows -t "$session:" -F '#{window_name}' 2>/dev/null
EOF
}

remote_kill_window() {
    ssh -o BatchMode=yes "$SSH_HOST" bash -s <<EOF
tmux kill-window -t "$target_session:$window_name" 2>/dev/null || true
EOF
}

remote_capture_pane() {
    ssh -o BatchMode=yes "$SSH_HOST" bash -s <<EOF
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
        echo "No tmux session exists in the container yet - creating '$target_session'."
        # -d: detached from the start, no attach/detach dance needed. -n
        # names the initial window directly. -c: new pane's starting
        # directory.
        ssh -o BatchMode=yes "$SSH_HOST" bash -s <<EOF
set -e
tmux new-session -d -s "$target_session" -n "$window_name" -c "$WORKDIR"
EOF
    else
        echo "Joining existing tmux session '$target_session' as a new window."
        # Trailing colon on the target forces session-name interpretation -
        # see remote_list_windows_in above for why this matters here.
        ssh -o BatchMode=yes "$SSH_HOST" bash -s <<EOF
set -e
tmux new-window -t "$target_session:" -n "$window_name" -c "$WORKDIR"
EOF
    fi
}

send_claude_command() {
    local claude_args="$1"
    ssh -o BatchMode=yes "$SSH_HOST" bash -s <<EOF
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
        # Check ready first: a non-blocking advisory (e.g. "Your login expires
        # in 2 days - run /login to renew") can appear on an otherwise-ready
        # screen and contains the literal substring "/login", which would
        # otherwise false-positive as a blocking login prompt below. A real
        # blocking trust/login/auth prompt never appears alongside the ready
        # markers, so checking ready first and returning early avoids that.
        if grep -qiE 'auto mode on|remote.control' <<<"$pane"; then
            echo "Ready. Session '$name' is live in window '$window_name' of tmux session '$target_session' in the ESPHome container, Remote Control enabled."
            # Surface this rather than silently ignore it - it's exactly the
            # banner wait_for_ready used to misread as a blocking login
            # prompt (see the check above); now that it's correctly treated
            # as non-blocking, still worth telling whoever's watching that
            # the shared ~/.claude auth on this host needs renewing soon.
            if grep -qiE 'login expires' <<<"$pane"; then
                echo "warning: $(grep -ioE '.{0,10}login expires.{0,40}' <<<"$pane" | head -1) - run /login in this window (or any session on this host) to renew." >&2
            fi
            return 0
        fi
        if grep -qiE 'do you trust|trust the files in this folder|/login|not authenticated|please (log|sign) in|invalid api key' <<<"$pane"; then
            echo "error: Claude is waiting on an unexpected prompt (trust/login/auth) - aborting and killing the window. Pane contents:" >&2
            echo "$pane" >&2
            remote_kill_window
            exit 1
        fi
    done
    echo "error: timed out after ${READY_TIMEOUT}s waiting for a ready state - inspect manually:" >&2
    echo "  ssh $SSH_HOST tmux attach -t $target_session" >&2
    exit 1
}

case "$cmd" in
new)
    select_target_session
    if [ "$create_session" = false ]; then
        mapfile -t windows < <(remote_list_windows_in "$target_session")
        for w in "${windows[@]}"; do
            if [ "$w" = "$window_name" ]; then
                echo "error: window '$window_name' already exists in tmux session '$target_session' - choose a different name" >&2
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
    # Two cases: the window still exists (the common one - you told Claude
    # to exit, which ends the process but leaves the tmux window/pane
    # sitting there with an idle shell) or it doesn't (the tmux
    # session/window itself ended, e.g. the container was recreated). Tell
    # them apart by asking tmux what's actually running in the pane right
    # now (#{pane_current_command}) rather than guessing from rendered text
    # - reliable because it's tmux's own bookkeeping, not a screen-scrape.
    session="$(remote_current_session)"
    existing_window=""
    if [ -n "$session" ]; then
        mapfile -t windows < <(remote_list_windows_in "$session")
        for w in "${windows[@]}"; do
            if [ "$w" = "$window_name" ]; then
                existing_window="$w"
                break
            fi
        done
    fi

    if [ -n "$existing_window" ]; then
        pane_command="$(ssh -o BatchMode=yes "$SSH_HOST" bash -s <<EOF
tmux list-panes -t "$session:$window_name" -F '#{pane_current_command}' 2>/dev/null
EOF
)"
        if [ "$pane_command" = "claude" ]; then
            echo "error: window '$window_name' still has Claude running in it - attach directly instead:" >&2
            echo "  ssh $SSH_HOST tmux attach -t $session" >&2
            exit 1
        fi
        echo "Window '$window_name' exists but Claude isn't running in it (pane command: '$pane_command') - resuming there."
        target_session="$session"
    else
        echo "No existing window named '$window_name' found - recreating it."
        select_target_session
        create_window
    fi

    send_claude_command "--resume '$name' --remote-control '$name'"

    echo "Waiting for Claude to reach a ready state..."
    wait_for_ready
    ;;
*)
    usage
    ;;
esac
