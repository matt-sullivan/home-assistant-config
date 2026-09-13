## Context

The repository uses YAML Home Assistant configuration with groups, input helpers, scripts, and automations. Emily's door-triggered lighting is in `automations.yaml`, while her sleep action is in `scripts.yaml`. There are no occupancy sensors for the managed rooms, so timeout policy is based on light state duration.

## Goals / Non-Goals

**Goals:**

- Keep one `input_select` as the source of truth for downstairs timeout policy.
- Keep bedtime activation sources separate from the timeout automations.
- Evaluate each member's `last_changed` duration independently so mode changes are honored for lights already on.
- Define and make testable Emily door-triggered lighting for bedtime mode.

**Non-Goals:**

- Occupancy inference or presence detection.
- Whole-house or upstairs mode support.
- Changes to Emily's bedroom sleep music or bedroom lighting scene beyond the bedtime-mode signal.

## Decisions

### Use one input select for downstairs mode

Use an `input_select` with `normal`, `bedtime`, and `pause` options. A single state represents the policy directly and avoids coordination bugs between separate enabled and bedtime booleans. `pause` is an explicit override that disables automatic timeout actions while leaving manual light control available.

### Use two template-triggered timeout automations

Create one automation for normal mode with a 3600-second threshold and one for bedtime mode with a 600-second threshold. Each template evaluates the current mode and the elapsed time for every managed light. The action turns off only members whose own threshold has elapsed. Neither automation acts while the mode is `pause`.

This avoids a long-running wait action and allows a mode change to affect lights that were already on. Evaluation is approximate to the threshold because Home Assistant reevaluates time-based templates periodically.

The automations SHALL run in parallel so simultaneous lights do not share or cancel one another's evaluation.

### Use a group as inventory, not as the timer

Define a named group for the managed lights. The group is useful for maintenance and dashboard presentation, while the automations expand its members and evaluate each entity independently.

### Keep bedtime activation in separate automations

Use separate automation paths for the 21:00 schedule and the Emily sleep action. Both set the same input select; neither owns timeout implementation. A future button can call the same mode-setting action without modifying the timeout automations. Use schedule from the custom scheduler component to trigger the time-based mode changes.

### Use bedtime mode for Emily door lighting

Use the existing door-open trigger with a condition that downstairs mode is `bedtime`. The trigger turns on the downstairs bathroom and pool table room lights only in bedtime mode; it does not turn on lights in normal or pause mode. Keep this trigger separate from timeout evaluation so the timeout policy can subsequently reclaim those lights.

## Risks / Trade-offs

- Without occupancy sensors, a light may turn off while someone is present. The longer normal timeout and explicit `pause` mode limit this risk.
- Time-based evaluation is approximate, and `last_changed` duration resets after restart or automation reload. This is acceptable for lighting and should be checked during validation.
- An explicit managed-light group limits accidental inclusion of unrelated lights; membership must match the specification.
