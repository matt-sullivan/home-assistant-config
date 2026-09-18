## Context

`group.family` includes people and the synthetic visitor person, so it cannot identify which member caused a home transition.

## Decisions

Keep `group.family` as the presence source for household automations. Move visitor reset into the visitor package and trigger it from real person arrivals; this centralizes the only explicit person list and avoids inspecting aggregate group transitions.