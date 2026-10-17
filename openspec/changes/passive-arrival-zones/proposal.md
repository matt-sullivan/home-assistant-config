# Keep presence home during GPS drift

Matt's and Sara's presence should stay home while they're at home, so away and arrival automations don't fire from GPS drift. The garage should still open early as either of them drives home, and, as a lower priority, open more reliably than it does today.

## Context

- A person's presence comes from their phone's location against three zones: Home, and two home street zones (HomeStreet1, HomeStreet2) that overlap Home and are used to open the garage early on arrival.
- An inaccurate reading from inside the house can land in a street zone, which makes the person away. This happened 116 times at 100 m accuracy before Matt's phone minimum accuracy was set to 50 m (2026-10-14), and 3 more times on 2026-10-15 at 22–44 m accuracy, causing 2 false arrivals.
- Presence drives the holiday lights when nobody is home, Welcome Lights on arrival, and the visitor presence reset.
- The Home zone can't grow beyond about 85 m: any bigger and it would cover a nearby street Matt and Sara regularly drive past.
- From 2026-10-04 to 10-15 the garage failed to open on 3 car arrivals: Sara on 10-06 (her first update was already home) and Matt twice on 10-13 (updates 27–58 s apart while driving skipped the street zones). Matt's phone was running Android Auto, which keeps GPS on, yet still reported only every ~27–50 s.

## Goals

- Matt and Sara stay home while they're at home, regardless of where within the Home zone their phone's reading lands.
- The garage still opens as Matt or Sara drives home in a car.
- The garage doesn't open when they leave, or from GPS drift while they're at home.
- Lower priority: fewer car arrivals where the garage doesn't open, without costing noticeable phone battery at home or opening the door when they drive past. An occasional miss is acceptable, and the logic stays simple.

## Approach

The street zones are changed to be 'passive' so they stop affecting presence, and a person is home or away based on the Home zone alone. The garage automations react to entering a street zone, or to reaching home, but only when the person was away immediately before. Use the android companion app feature to turn on high accuracy near home so Matt's phone reports its location more often while it is near home but not at home, so a drive in is less likely to skip the street zones.

## Trade-offs and limits

- Street zones no longer appear as a person's state in history, since they no longer set presence.
- A reading outside the Home zone still makes the person away, as it would without street zones; this change only stops street zones winning over Home.
- Some car arrivals will still be missed. The logic is kept simple, and an occasional manual open is acceptable.
- The street zones aren't made bigger. That would be the easiest fix, but they'd then catch drives through surrounding streets without coming home, which happen occasionally. The door would open with nobody arriving and would need closing automatically.
- The garage door is never closed automatically. Unattended, it could close on something; its force limit sensor should prevent damage, but it isn't worth the risk.
- Matt's frequent reporting isn't on for whole drives, to save battery. Android Auto already keeps GPS on, so the cost may be small, but frequent reports only help near home.
- Matt's frequent reporting is never on at home, where it would drain the battery. It only runs in an area around home, and only if that can be done reliably.
- Driving through nearby streets briefly turns on Matt's frequent reporting (more battery, and a persistent notification while it's on).
- The area around home where Matt's frequent reporting runs is kept small enough to exclude the restaurant 300 m from home, which they very occasionally go to for dinner. That leaves less approach before the street zones, so a late start can still miss an arrival.
- Arrival detection improves for Matt only. Sara's iPhone has no equivalent setting, and her phone already reports entering a street zone ~11–22 s before reaching home.

## Capabilities

- `home-presence` (new)
- `garage-arrival-open` (new)
