# Design

## Technical context

- `packages/lights-6952ha-unsensed.yaml`: relays as GPIO outputs, light state = relay (`RESTORE_DEFAULT_OFF`); sense inputs only feed diagnostics (Edges counters, disabled-by-default Power Status sensors). `hallway-stairs.yaml` also uses it, with ch1 on a 2-way whose sense legitimately differs from its relay.
- `packages/lights-6951ha.yaml`: the light writes through a filter that toggles the relay when the command differs from the sense; the light is restored at boot.
- `packages/udp-link-target.yaml`: receives `TOGGLE <link> <nonce>` and toggles a light once per nonce; broadcasts `STATE <link> <0|1>` 5× on change and every 30 s; counts toggles and duplicates. `udp-link-remote.yaml`: a press-only button sends `TOGGLE` 5× at 150 ms; `STATE` sets a light; exposes State Age.
- The remote's button LED is a monochromatic light (`button_led`, P7 PWM).

## Decisions

### Keep the media room unsensed, with names and a sense check

- `lights-media-room.yaml` keeps `packages/lights-6952ha-unsensed.yaml`, with `light_1_name: "Door"`, `light_2_name: "Interior"`.
- A sense check in `lights-media-room.yaml` itself, since no other device needs it: 1 s after each light state change, if the debounced sense differs from the light, count it in "Power Status N Unconfirmed Switches" (same name and 10 s pattern as the sensed packages).
- **Alternative:** sensed package — rejected because a stuck or flapping sense would break control and flap the group state, not just the display.
- **Alternative:** add the check to the unsensed package — rejected because `hallway-stairs.yaml` ch1 would count every remote switch.

### Pin the remote's relay

- `packages/lights-6951ha.yaml` gains `relay_fixed` (default `false`): when true, the button doesn't toggle the light and the filter never switches the relay. And `relay_restore_mode` (default `RESTORE_DEFAULT_OFF`).
- The remote sets `relay_fixed: true` and `relay_restore_mode` to `ALWAYS_ON` or `ALWAYS_OFF`, whichever makes each media room relay match its lamp (found by test).
- **Alternative:** only make the button press-only — rejected because the light's restore at boot could still switch the relay through the filter.

### Group the lamps behind one light on the media room

- New `packages/lights-group.yaml` (media room): an internal binary light `group_light` on a template output. Its state is "either lamp on", set with `light.control` whenever either lamp changes. A write turns both lamps to the written state only when it differs from "either on", so the state updates never switch anything.
- State updates are coalesced over 10 ms, so a group write that switches both lamps doesn't flip the group (and its broadcast) back in between.
- The output ignores its first write, which is the light's own restore (queued in setup, written on the first loop, after `on_boot`); after boot the group state is set from the lamps.
- `udp-link-target.yaml` with `link: media-room`, `light_id: group_light`, unchanged: a `TOGGLE` toggles the group (either on → both off, else both on), and `STATE` broadcasts "either on".
- **Alternative:** a group-specific target package — rejected because the group light lets both UDP packages be reused unchanged.

### Mirror the group state on the remote LED

- `lights-media-room-remote.yaml` includes `udp-link-remote.yaml` with `link: media-room`, `light_id: button_led`, `button_id: button_1`, unchanged. The LED is restored off and set by the first `STATE`.

## Risks

- **The remote's relay ends up in the other position** (fault, manual tinkering) → Door is inverted in HA and in the group state; Door's Unconfirmed Switches count rises on the next switch.
- **Wrong `relay_restore_mode` picked** → same as above; caught by the flash test.
- **No encryption** → any LAN device can send `TOGGLE`. Accepted, as for existing links.
