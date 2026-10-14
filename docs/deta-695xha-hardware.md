# DETA Grid Connect 2-way switches (6951HA / 6952HA): hardware notes

From reverse-engineering a 6951HA (WB3S), plus behaviour seen on installed units.
Each item is tagged with how sure we are:
- **[confirmed]**: measured, traced, or seen directly
- **[inferred]**: strongly implied by the confirmed facts
- **[speculation]**: plausible, not verified

## Boards

- Two boards joined by a 2×4 header:
  - Logic board `S714D-WF-B V06 2022-04-18`.
  - Mains board.
  - [confirmed]
- Both boards are shared between the 1- and 2-gang models; parts for the other variant are left unpopulated. [confirmed]
- The mains supply looks non-isolated: bridge + buck, no transformer. The logic board is at mains potential when powered. [inferred]

## Header (pin 1 = top-left, logic board top view)

Pin 1 is our own convention; the board has no pin-1 marking.

| Pin | Net | Logic board | Sure? |
|---|---|---|---|
| 1, 2 | VCC_IN | logic-board buck input | confirmed |
| 3, 4 | GND | | confirmed |
| 5 | RL1 | WB3S P14 (pos 4) | confirmed |
| 6 | SENSE1 (high = no traveller voltage) | 180k pull-up to 3V3; 22 Ω → Q_L gate (LED); 22 Ω → Q_R gate (P8 inverter) | confirmed |
| 7 | RL2 | WB3S P6 (pos 7) | confirmed |
| 8 | SENSE2 | unpopulated ch2 LED/inverter parts → WB3S P9 (pos 13) | confirmed (6951HA) |

Mains-board end of pins 5 and 7: see Relays below (inferred, not traced).

## Logic board

- Power: VCC_IN → SOT-23-6 buck + `3R3` inductor → 3V3. [confirmed]
  - VCC_IN voltage not measured.
- Touch controller: SOP-8 marked `A102 2143`, part unidentified. [confirmed]
  - Pads/springs connect to it through series resistors. The marking may be `01B` (EIA-96 code, 1 kΩ) rather than `101` (100 Ω); not measured.
  - Capacitive touch. [inferred]
  - Its outputs go to P26/P23. [speculation]
  - At most 2 buttons are ever active, so a 2-key IC fits. [inferred]
  - Candidates [speculation; none is marked "A102"]:
    - Holtek BS813A-1 (3-key) or BS812A-1 (2-key), as reportedly used in a DETA 6911HA
    - ICMAN SC02A
    - Tontek TTP224B-RO8N
  - Confirm by tracing VDD/VSS, key inputs and outputs against the datasheet pinouts.
- Status LED: P24 → 2.2k (`222`) → LED. [confirmed]
- Button LED: 3V3 → 1k → LEDs → Q_L drain. Q_L source → GND. [confirmed]
- Sense inverter: Q_R drain → WB3S P8. Q_R source → GND. [confirmed]
  - Active low; no pull-up seen, so it relies on the MCU pull-up. [inferred]
- Q_L / Q_R (SOT-23, marked `510`):
  - Pinout:
    - pin 1 (bottom-left, single pin at the top): gate, via 22 Ω
    - pin 2 (bottom-right): source → GND
    - pin 3 (top): drain
  - Gate resistors measured at 22 Ω. [confirmed]
  - Diode test: ~0.4 V source→drain only, nothing else. [confirmed]
  - Not P-channel: the only `510`-marked SOT-23 found (Cystech MTP5103N3) is a P-FET, and its body diode would point the other way. [confirmed]
  - Likely a small logic-level N-FET (2N7002 / SI2300 class). [speculation]
  - **N-MOSFET.** [confirmed] Logic board alone, header unplugged, 3V3 = 3.2 V: header pin 6 measured 3.15 V.
    - A BJT base would have clamped it to ~0.65 V.
    - The 50 mV drop is the meter's ~10 MΩ input loading the 180k pull-up.
  - The in-circuit gate-charge test failed only because the 180k path discharges the gate.

## Mains board (6951HA)

- Terminals:
  - Populated: `N-IN`, `L-IN`, `L1`, `L`, `L2`. [confirmed]
  - Unpopulated: `LL1`, `LL`, `LL2` (ch2 on the 6952HA). [confirmed]
- Relays:
  - Two fitted, both for ch1; two more footprints are unpopulated (ch2 on the 6952HA). [confirmed]
  - Back-side copper suggests the two ch1 relays form one changeover, L ↔ L1/L2. [inferred]
  - Both ch1 relays are driven from header 5 (P14). Back stairs (6951HA) does full local-XOR-remote switching with P14 alone, and P6 is never driven. [inferred]
    - Because the coils share one driver, there's no both-off or both-on state.
  - Header 7 (P6) probably goes only to the unpopulated ch2 drivers, so P6 would be a spare GPIO on the 6951HA. [inferred]
  - NC/NO contact use per relay not traced. [unknown]
- Supply:
  - Parts: fuses (T2A 250V), MOV, electrolytics, SOP-8 controller, `2204` 2.2 MΩ resistors, `1R50` sense resistors, inductor. [confirmed]
  - These form an off-line buck. [inferred]
- `S10`/`510` SOT-23s + `A7` diodes next to the relays. [confirmed]
  - Relay drivers and flyback diodes. [speculation]
- A large unpopulated area (through-hole resistor footprints, diodes, `~+−` bridge, SOP footprint) is ch2's sense circuit. [speculation]

## Sense circuit (ch1)

```
L1 ─ 1.2M (125) ─┐                 ┌ + ─► EL357N pin1 (LED anode)
                 ├─ MB10S bridge ~ ┤
L2 ─ 1.2M (125) ─┘                 └ − ─► EL357N pin2 (LED cathode)
EL357N pin4 (collector) ─► header 6 ─ 180k ─ 3V3 (logic board)
EL357N pin3 (emitter)   ─► GND ;  cap across pins 3–4
```
[confirmed]

- **The sense measures the voltage between the two travellers.** [confirmed by tracing]
- The relay connects L to one traveller; the far switch decides what the other traveller is connected to.

| State | L1–L2 voltage | Opto | Header 6 / button LED | P8 (ESPHome "Power Status") |
|---|---|---|---|---|
| Local relay and far switch disagree (lamp off) | ~240 V | on | low / off | off |
| Agree (lamp on) | ~0 V | off | high / on | on |
| Nothing connected | ~0 V | off | high / on | on |

- This gives "local relay XOR remote" at either end of the run. [confirmed on pooltable-stairs and back stairs]
- The button LED is on exactly when P8 reports "powered". It's hardware-driven from header 6; the MCU can't drive it, and P8 is only an input. [confirmed]
- Opto current ≈ 240 V / 2.4 MΩ ≈ 100 µA. [inferred]

## Hallway-stairs symptoms (6952HA)

- **Ch1, nothing connected:** LED permanently lit, P8 reads "on". This matches the table. [confirmed, explained]
- **Ch2:** P9 toggles continuously and the LED ramps slowly, whatever the lamp state. [confirmed]
  - Mechanism: header-6-equivalent sits mid-rail, so the LED FET is half on and P9 hovers around its logic threshold. The 180k pull-up and the C–E cap give the slow ramp. [inferred]
  - It shares its travellers with pooltable-stairs ch1, which reads cleanly. So the fault is probably in hallway ch2's own sense parts, not the wiring. [inferred]
  - Candidates [speculation], most likely first:
    1. leakage from flux/dust/moisture across the ~2.4 MΩ network
    2. a drifted or open 1.2 MΩ dropper
    3. a cracked or leaky C–E cap
    4. a wrong pull-up value
    5. a weak opto
  - Check against ch1 on the same unit once it's out of the wall.
- **Outcome (2026-10-10):**
  - Hallway moved to a CB3S logic board, and the stairs run moved to ch1 terminals; ch2 mains is empty.
  - Ch1 sense on the same mains board is now clean. So the fault was in the ch2 sense path, on either the old WB3S logic board (now in the media room) or this mains board's ch2. [confirmed]
- General risk: in the "agree" state the unused traveller is held only through 2.4 MΩ. Cable capacitance on long runs (~50–100 pF/m, i.e. a few MΩ at 50 Hz) can put tens of volts across the sense and make it marginal. [speculation]

## Media room (6952HA, WB3S logic board from the hallway)

- Door (ch1) is 2-way with the Media Room Remote (6951HA). The remote's relay is pinned with `relay_fixed: true` and `relay_restore_mode: ALWAYS_ON`, the position where Door's state equals the media room's relay. Interior (ch2) is 1-way.
- `lights-media-room.yaml` is unsensed (`packages/lights-6952ha-unsensed.yaml`), with a sense check that counts switches the sense doesn't confirm ("Power Status N Unconfirmed Switches"). Remote presses go over UDP to `packages/lights-group.yaml`: either lamp on → both off, else both on.
- Design and decisions: `openspec/changes/archive/2026-10-17-media-room-group-remote/`; behaviour: `openspec/specs/light-group-remote/spec.md`.
- Ch2 sense reads cleanly on this wiring so far, so the hallway ch2 fault is either on the hallway mains board or intermittent; the Unconfirmed Switches and Edges counters watch for it.

## Button LED firmware-control mod

1. Lift the sense-side end of Q_L's 22 Ω resistor.
2. Wire a spare GPIO to the lifted end; the 22 Ω stays in series.
3. Leave Q_R's 22 Ω in place so sensing still works.
4. Don't fit a pull-down. The LED is undefined only while the GPIO floats, and the 1k limits its current to ~1–2 mA.
5. Drive it as a plain push-pull GPIO output: high = LED on.

Spare GPIOs (WB3S):
- 6951HA: P9 (pos 13), P7 (pos 10), P0/P1 (pos 11/12), P10/P11 (pos 15/16), and probably P6 (pos 7, routed to header 7 but likely unused).
- 6952HA: the same except P9, which is used by ch2 sense.
- P10/P11 are the serial-flash UART; P0/P1 are UART2, so check the logger isn't using them.

## Open questions

- Each relay's contact arrangement. A continuity check would confirm the header 5 → both-relays drive.
- VCC_IN voltage.
- A102 identity and pinout.
- `510` part number.
- How ch2's sense is built on a 6952HA mains board.
- Root cause of the hallway ch2 fault.
