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

### Use eligibility-triggered timeout automations

Create one template-triggered automation for normal mode with a 3600-second threshold and one for bedtime mode with a 600-second threshold. Each trigger becomes true only when at least one managed light has reached its active-mode threshold. The action still evaluates each member independently and turns off only eligible lights. Neither automation acts while the mode is `pause`.

This avoids a long-running wait action and allows a mode change to affect lights that were already on. Evaluation is approximate to the threshold because Home Assistant reevaluates time-based templates periodically.

The automations SHALL run in parallel so simultaneous lights do not share or cancel one another's evaluation.

### Use a group as inventory, not as the timer

Define a named group for the managed lights. The group is useful for maintenance and dashboard presentation, while the automations expand its members and evaluate each entity independently. Exclude `light.emily_makeup`. That light has an existing always-powered behavior that turns it back on shortly after it is switched off, so it cannot participate meaningfully in timeout management yet

### Keep bedtime activation sources separate

Use the custom Scheduler component for daily mode transitions: select `bedtime` at 21:00 and `normal` at 06:00. Each schedule directly calls the input-select service. Emily's sleep action sets the same input select directly. Neither activation source owns timeout implementation. A future button can call the same input-select service without modifying the timeout automations.

### Use bedtime mode for Emily door lighting

Use the existing door-open trigger with a condition that downstairs mode is `bedtime`. The trigger turns on the downstairs bathroom and pool table room lights only in bedtime mode; it does not turn on lights in normal or pause mode. Keep this trigger separate from timeout evaluation so the timeout policy can subsequently reclaim those lights.

## Risks / Trade-offs

- Without occupancy sensors, a light may turn off while someone is present. The longer normal timeout and explicit `pause` mode limit this risk.
- Time-based evaluation is approximate, and `last_changed` duration resets after restart or automation reload. This is acceptable for lighting and should be checked during validation.
- An explicit managed-light group limits accidental inclusion of unrelated lights; membership must match the specification.
