# HA brief: linked lights update

## What to do
Clean up HA after a firmware update to the stair and hallway light switches:
- delete orphaned and removed entities;
- repoint every reference to the new entity IDs;
- retire `group.hallway_lights`;
- make the power-sensor diagnostics consistent;
- create a "Hallway" area and move four lights/devices into it;
- update Google exposure.

Don't create new automations. Report back when done (see the last item).

## Goal and context
- **Goal:**
  - Every lamp has exactly one HA light entity showing its true state.
  - Google on/off commands never act as toggles.
  - Buttons wired to no lamp control their lamp without needing HA.
- **What changed in the firmware:**
  - 2-way switches now sense the lamp's real power state.
  - Several entities were renamed or removed. ESPHome derives the unique ID from the entity name, so each rename created a new entity and orphaned the old one.
  - Three buttons wired to no lamp are now **remote buttons** that toggle their lamp directly over UDP; HA isn't involved:
    - kitchen ch2 → entry Hallway Light;
    - hallway-stairs ch1 → pool room Landing;
    - laundry-door ch3 → Back Stairs Light.
  - Their "Remote" lights, and the link and power-sensor diagnostics, are diagnostic entities, recorded for debugging. Don't reference them or expose them to Google.
  - The old `group.hallway_lights` sync, where kitchen and entry called an HA group, is gone.

## Items

1. **Renamed entities.**
   - History isn't needed: delete each orphan and keep the new entity ID.
   - Update every reference to the old ID: automations, scripts, groups, dashboards, `customize.yaml`, Google exposure/aliases, areas.

   | Device | Old | New |
   |---|---|---|
   | lights-entry ch1 | "Hallway Entry" (`light.hallway_entry`) | "Hallway Light" |
   | lights-pooltable-stairs ch1 | "Stairs Light" | "Internal Stairs Light" |
   | lights-pooltable-stairs ch2 | "Hallway Light" | "Downstairs Hallway Light" |
2. **Removed entities.** Delete them and update their references:
   - hallway-stairs "Internal Stair Light" (`light.hallway_stairs_internal_stair_light`)
   - lights-kitchen "Hallway Kitchen" (`light.hallway_kitchen`), replaced by diagnostic "Hallway Remote"
   - hallway-stairs "Stair Bottom Landing Light", replaced by diagnostic "Landing Remote"
   - lights-laundry-door "Stairs", replaced by diagnostic "Back Stairs Remote"
3. **Power-sense diagnostics consistency.**
   - The entities: every "Power Status*" entity (status, Edges, Unconfirmed Switches) on lights-pooltable-stairs, lights-back-stairs, lights-sara-office and hallway-stairs.
   - Make them all enabled, not hidden, with no name or area overrides; some pre-date this change and may have manual registry settings.
   - Exception: **disable** hallway-stairs "Power Status 1" and "Power Status 2". A faulty input there can flap many times per second; their "Edges" counts stay enabled for history.
4. **`group.hallway_lights`.** Retire it and replace its references (the `holiday_lights` group, automations, scripts, dashboards) with the new Hallway Light entity.
5. **Hallway area.** Create an area named **"Hallway"** (the upstairs hallway), then assign:

   | What | Kind | How |
   |---|---|---|
   | lights-entry "Hallway Light" | entity | set the entity's area; its device stays in its current area |
   | lights-pooltable-stairs "Internal Stairs Light" | entity | set the entity's area; its device stays in its current area |
   | lights-breakfast-bar "Hallway Toilet Light" | entity | set the entity's area; its device stays in its current area |
   | hallway-stairs | device | set the device's area; its entities follow, unless an entity has its own area override, in which case clear it |

   Change no other areas. Downstairs Hallway Light stays where it is.
6. **Google exposure:** expose Hallway Light, pool room Landing, Back Stairs Light, Internal Stairs Light and Downstairs Hallway Light.
   - Outcome: the user later removed pool room Landing's exposure on purpose.
7. **Report:** every item done, with the entity IDs used, plus any references changed.

## Out of scope
- ESPHome device config.
- New automations; only update references in existing ones.
