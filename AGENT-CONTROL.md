# Agent Control

Instructions for a supervisor session (e.g. on agent-srv) managing Claude
sessions for this project. Use `scripts/claude-ha-session.sh` wherever
possible.

The script launches or resumes Claude Code on the Home Assistant host (the
"Advanced SSH & Web Terminal" add-on container) as one window per agent in
the existing tmux session, with Remote Control enabled. Reconnect from
claude.ai/code or the Claude app.

## Prerequisites

- Run from a local checkout of this repo.
- SSH alias `homeassistant` with non-interactive key auth (`BatchMode=yes`).
- Claude on the host is logged in and `/config` is already trusted; the
  script aborts on trust/login prompts rather than answering them.

## Start a new session

`scripts/claude-ha-session.sh new <name>`

Starts session `<name>` in a new tmux window. Names can't contain `'`;
spaces become `_` in the window name. Fails if the window already exists.

## Resume an existing session

`scripts/claude-ha-session.sh resume <name>`

Resumes in its window if idle, or recreates the window if gone. Fails if
Claude is still running in it.

## Inspect and interact

```bash
ssh homeassistant tmux list-windows -a \
    -F "'#{session_name}:#{window_name} #{pane_current_command}'"
ssh homeassistant tmux capture-pane -p -t <session>:<window>
ssh homeassistant tmux send-keys -t <session>:<window> "'<text>'" Enter
```

Only kill a window when its agent is finished; never kill the tmux session.

## Checkout / No Worktrees

- No worktrees: all sessions share one checkout at `/config` on `master`.
- Don't run concurrent sessions that edit the same files or OpenSpec change.
- Agents must commit only their own files and coordinate rebases/pushes.
- Session agents follow `AGENTS.md`; ESPHome work belongs elsewhere
  (`esphome-main` branch, outside the HA VM).
