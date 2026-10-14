# Tasks

## 1. Remote entities

- [x] 1.1 Make the remote's "Light" and "Button LED" (renamed from "Button LED Test") internal in `lights-media-room-remote.yaml` and flash it; verify: HA shows only diagnostics for the remote.

## 2. Media room

- [x] 2.1 Create `packages/lights-group.yaml` per design; in `lights-media-room.yaml` name the lights "Door"/"Interior", add the sense check, `lights-group.yaml` and `udp-link-target.yaml` (`link: media-room`, `light_id: group_light`); verify: `esphome compile lights-media-room.yaml` passes.

## 3. Remote

- [x] 3.1 Add `relay_fixed` and `relay_restore_mode` to `packages/lights-6951ha.yaml`; verify: `esphome compile lights-back-stairs.yaml` passes (defaults unchanged).
- [x] 3.2 In `lights-media-room-remote.yaml` set `relay_fixed: true` and include `udp-link-remote.yaml` (`link: media-room`, `light_id: button_led`, `button_id: button_1`); verify: `esphome compile lights-media-room-remote.yaml` passes.

## 4. Flash and pin

- [x] 4.1 Flash both devices; set `relay_restore_mode` to the position where each media room relay matches its lamp, and reflash the remote if needed; verify: HA "Door" and "Interior" match the lamps. (manual) — `ALWAYS_ON`; senses agree with relays (lamps to be confirmed in 5.1)
- [x] 4.2 Add the section 5 items to `TESTING.md`; verify: each appears there.

## 5. Final verification

- [x] 5.1 Scenarios "Either lamp on", "Both lamps off" and "Remote press reported", from every starting state (both off, both on, only Door, only Interior): HA matches the lamps after each press. (manual) — passed
- [x] 5.2 Scenario "Local switch of one lamp": each media room button and HA command changes only its own lamp. (manual) — passed
- [x] 5.3 Scenario "Turn on an already-on lamp": HA on/off in the current state changes nothing. (manual) — passed
- [x] 5.4 Scenario "Only Interior on", and the LED in the other states: the remote LED is on when any lamp is on. (manual) — passed
- [x] 5.5 Scenario "Device reboot": reboot each device; no lamp changes, and the remote LED is correct within 30 s. (manual) — passed after the first-write fix; lamps flash briefly during reboot (relay pins drop until restore)
- [x] 5.6 Scenarios "Healthy link" and "Link down": a press raises "Link media-room Toggles" by 1 and duplicates rise; the remote's State Age stays under ~30 s, and rises while the media room is rebooting. (manual) — passed
- [x] 5.7 The Door and Interior button LEDs follow their lamps. (manual) — passed
- [ ] 5.8 Scenario "Sense fault": both channels' Unconfirmed Switches and Edges stay quiet over the following weeks. (deferred)

## 6. Wrap-up

- [x] 6.1 Record findings (relay position, ch2 sense) in the change's `session-notes.md` and `docs/deta-695xha-hardware.md`; update `AGENTS.md` device notes if anything general was learned; verify: the docs name the media room's packages.
