# Tasks

## 1. 6951HA/6952HA packages

- [x] 1.1 Replace `packages/lights-6952ha.yaml` with `packages/lights-6952ha-sensed.yaml` and `packages/lights-6952ha-unsensed.yaml` per design, and update devices; verify `esphome compile` passes for both.
  - `lights-pooltable-stairs.yaml` (sensed): ch1 "Internal Stairs Light", ch2 "Downstairs Hallway Light"; remove the temporary P7/P9 diagnostics.
  - `hallway-stairs.yaml` (unsensed): ch1 "Landing Remote", press-only; ch2 internal.
- [x] 1.2 Create `packages/lights-6951ha.yaml` and migrate `lights-back-stairs.yaml` to it; verify `esphome compile` passes.
- [x] 1.3 Add test items for groups 1–3 to `TESTING.md`.

## 2. Remote buttons over UDP

- [x] 2.1 In `packages/lights-6903ha-common.yaml`, replace the `switch_N_group` HA action calls with `switch_N_press_only` (button doesn't toggle). Set `lights-laundry-door.yaml` ch3 to "Back Stairs Remote", press-only. Verify `esphome compile` passes for the 6903HA devices and no config contains `homeassistant.service`.
- [x] 2.2 Remove the unused `switch_N_group` logic from `packages/lights-6911-6912ha-common.yaml`; verify `esphome compile` passes for the devices that use it.
- [x] 2.3 In `packages/lights-6904ha-common.yaml`, replace `light_N_group` with `light_N_press_only`. Verify `esphome compile` passes for kitchen, entry and `lights-downstairs-deck.yaml`.
  - `lights-kitchen.yaml`: ch2 "Hallway Remote", press-only.
  - `lights-entry.yaml`: ch1 renamed "Hallway Light", group substitution removed.
- [x] 2.4 Create `packages/udp-link-target.yaml` and `packages/udp-link-remote.yaml` per design. Add a target to entry ch1 (`hallway-light`), pool room ch1 (`landing`) and back stairs (`back-stairs`). Add a remote to kitchen ch2, laundry-door ch3 and hallway-stairs ch1. Remote lights are enabled diagnostic entities. Verify `esphome compile` passes for all six.

## 3. Sara Office, status LED, diagnostics

- [x] 3.1 Replace the `lights-sara-office.yaml` light logic with a plain binary light on an inverted GPIO output (P14). Stop the P8 sensor driving the light, the debug script and the dummy output. Keep the Long Press event; add the 10 s long-press reboot. Verify `esphome compile` passes.
- [x] 3.2 Find the 6914HA series 3 status LED with a temporary Spare Bedroom test build (found: P22, active low), set it in `packages/lights-6914ha-series3.yaml`, delete the test config, and reflash Spare Bedroom with its normal config.

- [x] 3.3 Add the diagnostics per design (counters publish on change): observe-only status and edges on unused sense inputs (hallway-stairs, Sara Office), unconfirmed switches on the sensed packages, toggles/duplicates on link targets, state age on link remotes. Verify `esphome compile` passes for the affected devices.

## 4. HA handoff (master branch, "linked lights update" agent)

- [x] 4.1 Get user confirmation of the brief in `ha-handoff.md`. All items depend on flashing, so delegation waits for 5.1.
- [x] 4.2 Delegate to the "linked lights update" agent; verify its report confirms each brief item.

## 5. Deploy and physical tests (user present)

- [x] 5.0 Check the Wi-Fi access points don't filter broadcast/multicast between clients (e.g. multicast/broadcast control, client isolation). Verified: laundry-door receives back stairs' STATE broadcasts.
- [x] 5.1 Flash the affected devices: pooltable-stairs, hallway-stairs, back-stairs, laundry-door, kitchen, entry, pooltable-room, sara-office, emily. Verify each comes online with the expected entities in HA.
- [x] 5.2 Run all `TESTING.md` items for this change and record the results. The user skipped the remaining low-value items: reboot with a lamp on via the remote switch, remote LED after a remote reboot, Unconfirmed Switches over time, observe-only diagnostics recorded, no toggle on reboot. The lounge fan status LED is checked when they're installed.
- [x] 5.3 Update `AGENTS.md` and package comments with the 6952HA WB3S pin map, the per-model packages and the UDP remote button pattern; verify the docs reference the correct package files.
