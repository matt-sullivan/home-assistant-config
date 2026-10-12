## 1. Blueprint

- [x] 1.1 In `blueprints/automation/homeassistant/air_con_limits.yaml`, apply the design:
  - Replace the `door_open` template trigger and `homeassistant` start trigger (and its comment) with the door, climate and startup triggers.
  - Replace the door branch's template re-check with the native door and climate `for: 5 min` conditions.
  - Update the blueprint and `door_sensors` descriptions for the fan only exemption.
  - Run `ha core check`, reload automations, and verify the four `Limit * Air Con` automations load without errors.

## 2. Validation

- [x] 2.1 Render the startup trigger template and confirm it is true now (uptime > 10 min) and false for an uptime under 10 minutes or `sensor.uptime` unavailable.
- [x] 2.2 Verify each item (traces/logbook or live test):
  - [x] Cool/heat with door open 5 min: turns off, with notification naming the door.
  - [x] Door closed within 5 min while heating/cooling: keeps running.
  - [x] Door open, then air con turned to cool: turns off 5 min after the switch.
  - [x] Dry with door open 5 min: turns off.
  - [x] Fan only with door open > 5 min: keeps running, no notification.
  - [x] Fan only → cool with door open: turns off ~5 min after the switch.
  - [x] HA restart while cooling with door open: not turned off immediately; turned off ~10 min after startup.
  - [x] HA restart while cooling, door opened ~8 min after startup (inside the startup trigger's window): not turned off by the startup trigger; turned off 5 min after the door opened.
  - [x] HA restart in fan only with door open: keeps running.
  - [x] An instance with no door sensors loads without errors and never turns off the air con (temporary test automation, removed afterwards).
  - [x] Temperature clamping still works and no automation runs occur without a state change.
