# Design

## Context

- 6952HA on WB3S (likely Series 1) pins:
  - Relays: P14 (ch1), P6 (ch2).
  - Buttons: P26 (ch1), P23 (ch2).
  - Power-status inputs, active low: P8 (ch1), P9 (ch2).
  - P9 was derived from the documented CB3S Series 2 pins (P7/P8) by module position (WB3S pos 14 = P8, pos 13 = P9) and confirmed on pooltable-stairs. On hallway-stairs, P9 toggles continuously, so that unit's ch2 sensor is treated as faulty.
- The existing sensed-channel pattern (6952HA ch1, back stairs) is:
  - A binary light whose template output toggles the relay only when the requested state differs from the sensor.
  - The sensor's `on_state` writes the light state.
  - Binary sensors default to `trigger_on_initial_state: false`, so the light does not reflect the sensed state at boot.
- Existing link pattern (kitchen/entry, 6903HA/6904HA `*_group` substitutions): a local button press toggles the light, then calls `homeassistant.turn_on`/`turn_off` on an HA group. This needs per-device HA action permission and hard-codes HA entity IDs in firmware.
- Lamp-less buttons:
  - kitchen ch2 (hallway lamp on entry ch1);
  - hallway-stairs ch1 (rewired; landing lamp on pool room ch1);
  - laundry-door ch3 (back stairs lamp on lights-back-stairs, which also has a dumb 2-way switch).
- On DETA switches the relay pin drives that button's LED. On 2-way models (6951HA/6952HA) the LED follows the power-sensing circuit instead (confirmed on hallway-stairs and pooltable-stairs).
- Back stairs (6951HA) is configured inline in its device file, not in a package.

## Goals / Non-Goals

**Goals:**
- Device files contain only substitutions and package includes.

**Non-Goals:**
- Repairing hallway-stairs ch2 sensing hardware.
- Button LEDs on 2-way hardware; they are hardware-driven by the sense circuit.

## Decisions

### Per-model packages
- One package per model variant, configured by substitutions in the device file. This matches the 6903HA/6904HA/6914HA style.
  - `packages/lights-6952ha-sensed.yaml`: both channels sensed (P8, P9). Used by pooltable-stairs.
  - `packages/lights-6951ha.yaml`: one sensed channel (P8). Used by back stairs.
  - `packages/lights-6952ha-unsensed.yaml`: both channels plain; light state is the relay state. Used by hallway-stairs.
    - Substitutions `light_N_internal` and `light_N_press_only`.
    - ch1 "Landing Remote" is press-only.
    - ch2 is internal: its state is meaningless in a 2-way circuit, but toggling still switches the lamp, and pooltable-stairs ch1 reports the change.
- The sensed logic, duplicated between the 1- and 2-gang packages, is:
  - a raw GPIO sense input (internal);
  - a filtered activation status: a template binary sensor from the raw input, with `delayed_on_off: 30ms` and `trigger_on_initial_state: true`, that writes the light state;
  - the idempotent template output and the light.
- That duplication is accepted to keep each package flat and readable; the packages note it.
- Sara Office defines its status LED inline; it no longer shares a 6952HA package.
- Swapping the hallway-stairs channel wiring (internal stairs onto ch1) is optional.
  - It would show whether the ch2 sense fault and the LED pulsing follow the channel (a unit fault) or the wiring.
  - It isn't needed functionally.
- Alternative: per-channel packages via `!include` vars. Rejected: they remove little duplication, and their style differs from the other packages.
- Alternative: a substitution flag to disable sensing. Rejected: ESPHome can't conditionally omit a GPIO component, and a configured noisy P9 still runs.

### Diagnostics
- All are `entity_category: diagnostic`, enabled, and recorded in HA history, except the hallway-stairs observe-only status (below). Counters and edge counts update every 10 s, which bounds history growth even on a faulty input.
- Every power-sense input on 2-way hardware, including unused ones (hallway-stairs P8/P9, Sara Office P8; observed only, no effect on the lights):
  - debounced "Power Status" and its edge count per 10 s.
  - The hallway-stairs observe-only status entities are disabled by default, since its faulty P9 can flap many times per second; its Edges counts carry the history.
- Each power sensor in use (pooltable-stairs, back stairs) additionally has:
  - "Unconfirmed Switches": relay switches whose sense input didn't follow within 1 s (breaker off, lamp circuit fault, or failing sensor), counted since boot.
- Link target: "Link <link> Toggles" and "Duplicate Toggles", counted since boot. With 5 copies per press, duplicates ≈ 4 × toggles means no packet loss.
- Link remote: "Link <link> State Age", seconds since the last `STATE`. It should stay under ~30 s.
- The raw sense input counts every transition into a global.
- A template sensor (`entity_category: diagnostic`, 10 s interval) publishes the count and resets it, and logs non-zero counts.
- Removing the diagnostics later means deleting this block from the package.
- The temporary P7 and P9 diagnostics in `lights-pooltable-stairs.yaml` are removed.

### Remote buttons: UDP between devices
- Raw ESPHome `udp` messages, broadcast on the existing Wi-Fi (port 18511). This works on BK72xx and ESP8266.
  - Rejected: `http_request` (unsupported on BK72xx); `packet_transport` state sharing (a lost packet loses a press); ESP-NOW (ESP32 only).
- Messages (ASCII):
  - `TOGGLE <link> <nonce>`, remote → target.
    - A new random non-zero nonce per press, sent 5× at 150 ms intervals (~600 ms window).
    - The target toggles once per new nonce, remembering only the last one (each target has a single remote).
    - Toggle rather than absolute on/off, so a stale state on the remote can't turn a press into a no-op.
  - `STATE <link> <0|1>`, target → any listener: 5× at 150 ms on every change, plus every 30 s.
- Why retries: broadcast frames get no Wi-Fi ACK or retransmit, and power-save clients receive broadcasts only at DTIM beacons (~100–300 ms). The fixed 600 ms window covers single-frame loss, short bursts and DTIM delay. Roaming and reconnect outages (seconds) aren't covered; press again.
- `packages/udp-link-target.yaml` (vars `link`, `light_id`):
  - an `on_receive` handler;
  - the last-nonce global;
  - the state script and 30 s interval;
  - `!extend` of the light's `on_turn_on`/`on_turn_off`.
  - It knows nothing about remotes.
- `packages/udp-link-remote.yaml` (vars `link`, `light_id`, `button_id`):
  - `!extend` of the button's `on_press` (new nonce + send script);
  - an `on_receive` handler that sets the remote light from `STATE`;
  - `!extend` of the remote light to `entity_category: diagnostic`.
- Hallway-stairs ch1 mirrors too. Its LED follows the sense circuit, so it may not show the state; any side effect of switching that relay is checked physically.
- Press-only channels skip their own toggle: 6903HA `switch_N_press_only`, 6904HA `light_N_press_only`, 6952HA-unsensed `light_N_press_only`.
- Remote lights are enabled diagnostic entities. They're recorded in HA history for diagnosing faults, and left out of area/device targeting and assistant auto-exposure. `internal` would give no visibility; disabled entities would record nothing.
- The mirror follows the target's state, so it covers every source of change. Back stairs is sensed, so its dumb 2-way switch is covered too.
- Loop-free:
  - Only a button press sends `TOGGLE`.
  - `STATE` only sets the remote light, which sends nothing.
- `light_N_group`/`switch_N_group` (devices calling HA actions) is removed from the 6903HA, 6904HA and 6911/6912HA packages.
- Alternative: HA events and automations. Rejected: remotes would stop working when HA is down.
- No encryption: any LAN device can send a `TOGGLE`. Accepted for a home LAN.
- Broadcast rather than unicast.
  - Unicast `TOGGLE` (remote → target IP) would gain Wi-Fi link-layer retries, but needs DHCP reservations and IPs in configs.
  - The app-level retries already cover broadcast loss on one subnet.
  - Fall back to unicast only if testing shows missed presses.

### Sara Office
- Today: a binary light on a no-op output, whose `on_turn_on`/`on_turn_off` drive the relay inverted (lamp on = relay off).
- Problem: at boot the light restores off without firing a trigger, and the relay defaults off. If lamp-on is relay-off, the lamp is on while HA shows off.
- New: a plain binary light on an inverted GPIO output (P14). Light state and relay are then consistent by construction.
- The power sensor (P8) no longer drives the light; it's kept as an observe-only diagnostic. The debug script and the dummy output are removed.
- Polarity is carried over from the current config and confirmed by a physical test.
- The lamp briefly lights during boot: it's on when the relay is de-energised, and the relay pin isn't driven until the firmware starts. Accepted. Moving the lamp to the other 2-way terminal would remove it.
- Adds the 10 s long-press reboot used by the other light configs.
- Alternative: use the sensed 6952HA package. Rejected: there is no remote switch, so sensing adds parts with no benefit.

### Status LED (6914HA series 3)
- The LED is on **P22**, active low (`inverted: true`). It was found with a temporary Spare Bedroom build that exposed P10, P11 and P21–P24 as switches.
- P10 had been translated by module position from series 2 (WB3S RX1). That translation doesn't hold for this LED, and the polarity was already right.
- The fix is `status_led_pin: P22` in `packages/lights-6914ha-series3.yaml`. It applies to Emily, Spare Bedroom and the lounge fans.

## Risks / Trade-offs

- [Broadcast filtered by an access point (e.g. multicast/broadcast control) or devices on different subnets] → remotes don't work. Check the access point settings before flashing.
- [Wi-Fi outage longer than the 600 ms retry window] → the press is lost; press again.
- [Hallway-stairs ch1 LED is sense-driven (it stays on)] → the Landing Remote LED may not show Landing's state. Accepted.
- [hallway-stairs ch2 relay toggle while HA is down] → the lamp still switches. Only HA state lags.
- [Renamed entities: pooltable-stairs ch1/ch2, entry ch1, laundry-door ch3] → ESPHome derives HA's unique ID from the name, so each rename creates a new entity ID and orphans the old one. History loss is accepted; the HA agent deletes the orphans and updates all references to the new IDs.
