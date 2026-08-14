---
name: power-monitoring-patterns
description: "Use when: adding or updating home power monitoring entities, counters, utility meters, tariff totals, or cost sensors. Keywords: power, energy, integration sensor, utility_meter, tariff, daily, monthly, cost, kWh."
---

# Power Monitoring Patterns

Use this skill when adding or updating power monitoring in this repository.

## Outcome

- Preserve the established power-to-energy-to-cost pipeline.
- Keep naming and grouping consistent across files.
- Avoid common drift errors where entity IDs stop lining up.

Companion quick template:

- See `TEMPLATES.md` in this same skill directory for copy-paste skeletons.

## Canonical Pipeline

Power monitoring is modeled in four layers:

1. Power measurement sensors (W)
2. Integration counters (kWh cumulative)
3. Utility meters (daily/monthly windows, with tariffs where applicable)
4. Template sensors for rolled-up energy totals and cost totals

### 1) Power Measurement Layer

Primary definitions are in `packages/common/power_calcs.yaml`.

- House groups are template power sensors (`device_class: power`, `state_class: measurement`):
  - `sensor.power_house_total`
  - `sensor.power_house_outlets`
  - `sensor.power_house_air_con`
  - `sensor.power_house_lights`
  - `sensor.power_house_hot_water`
  - `sensor.power_house_other`
- `sensor.power_outlets_other` is a template sensor, but not one of the house-level groups. It is a residual bucket for untracked outlet loads.
- Some monitored devices are represented directly by existing source sensors (for example `sensor.kitchen_dishwasher_power`) and are not redefined as template sensors here.

### 2) Integration Counter Layer

Defined in `packages/common/power_energy_counters.yaml` using `platform: integration`.

Pattern:

```yaml
- platform: integration
  source: sensor.<power_sensor>
  name: "<Title> Energy Counter"
  unique_id: <slug>_energy_counter
  unit_prefix: k
  round: 2
  max_sub_interval:
    minutes: 5
```

Key rule:

- `source` must reference the real power entity ID exactly.

### 3) Utility Meter Layer

Defined in `packages/common/power_energy_periods.yaml`.

Each counter typically has two utility meters:

- `*_energy_daily` with `cycle: daily`
- `*_energy_monthly` with `cron: "0 0 26 * *"`

Most meters are TOU (time-of-use) with tariffs:

```yaml
tariffs:
  - peak
  - shoulder
  - off-peak
```

The hot water meter is a non-TOU exception and has no tariffs defined (because it's charged the same rate all day.)

### 4) Template Energy and Cost Layer

- `packages/common/power_energy_periods.yaml` contains template sensors that sum TOU tariff buckets into a single daily/monthly kWh total.
- `packages/common/power_costs.yaml` contains:
  - tariff input numbers (c/kWh)
  - automation to switch utility-meter tariffs by time
  - template sensors for daily/monthly dollar costs (same concept as the energy total template sensors in power_energy_periods.yaml, but multiplied by the appropriate tariff rate).

## Naming Conventions

### Core Slug Pattern

Most entities follow:

- Group: `power_<scope>_<topic>`
- Outlet/device: `power_outlet_<area>_<device>`
- Air con monitor devices: `power_air_con_<room_or_person>_air_con_power_monitor`

Then suffix by layer:

- power sensor: no suffix or `_power`
- integration: `_energy_counter`
- utility meter: `_energy_daily` / `_energy_monthly`
- cost sensor: `_cost_daily` / `_cost_monthly`

### Important Cross-File Alignment

For a given slug `<x>`, keep aligned:

- Counter `unique_id`: `<x>_energy_counter`
- Utility meter source: `sensor.<x>_energy_counter`
- Utility meter IDs: `<x>_energy_daily`, `<x>_energy_monthly`
- Cost sensors consume utility outputs from those exact IDs

If one layer deviates, downstream sensors either break or silently read zero.

### Integration Counter Naming Pattern (Important)

Integration counters intentionally use **two separate identifiers** with different purposes:

- `name`: short, human-readable display label (e.g. `"Clothes Dryer Energy Counter"`)
- `unique_id`: full taxonomic slug matching the downstream pipeline (e.g. `power_outlet_downstairs_clothes_dryer_energy_counter`)

On first load, HA derives `entity_id` from `name`, producing a short slug. **Renaming the entity to match `unique_id` is a required post-load step** — via the HA UI or MCP calling `ha_set_entity(entity_id=..., new_entity_id=...)`. Once renamed, the registry owns that entity_id permanently — subsequent `name` changes in YAML have no effect on it.

This is the established pattern across all device-level counters in this repo. The house-level group counters (`Power House Total...` etc.) happen to not need this rename because their readable names already slug to the correct full unique_id.

Layer comparison:

| Layer | entity_id source | Rename needed? |
|---|---|---|
| Template sensors (`power_calcs.yaml`) | `default_entity_id` field | No — pinned in YAML |
| Integration counters | Derived from `name` on first load, then registry-owned | **Yes — rename in UI after first load** |
| Utility meters | YAML key is the entity_id directly | No — deterministic |
| Input numbers / helpers | YAML key is the entity_id directly | No — deterministic |

Fresh-install caveat: if `.storage` is lost (full reinstall), the registry rename is gone and entity_ids revert to name-derived slugs. Downstream utility meter `source:` references will break. This is an accepted trade-off; normal HA restore practice preserves `.storage`.

## Grouping Model

### House-Level Groups

Derived in `power_calcs.yaml`:

- `power_house_total` = `power_meter_total_power + power_meter_hot_water_power`
- `power_house_outlets` = `power_meter_gpo_power - selected split air-con monitors`
- `power_house_air_con` = `power_meter_air_con_power + selected split air-con monitors`
- `power_house_other` = residual after subtracting known categories from total

### GPO/Outlet-Level Groups

- Individual appliance power sensors are integrated one-by-one.
- `power_outlets_other` is residual: house outlets minus explicitly tracked outlet loads.

This keeps both explicit device tracking and a balancing "other" bucket.

## Known Exceptions to the General Rules

1. Hot water is non-TOU in this model.
- Utility meters for hot water omit tariffs.
- Cost uses `input_number.power_tariff_hot_water_c_per_kwh` and total daily/monthly kWh (not peak/shoulder/off-peak buckets).
- Tariff switching automation excludes hot water via `reject('search', '_hot_water_')`.

2. Living room air con has an ID naming irregularity.
- Counter unique ID is `living_room_air_con_energy_counter` (missing the broader `power_air_con_*` prefix used by other air-con entities).
- Utility meter IDs still use `power_air_con_living_room_air_con_*` naming while sourcing `sensor.living_room_air_con_energy_counter`.

3. Some source sensor names include repeated area words.
- Examples: `sensor.kitchen_kitchen_fridge_power`, `sensor.downstairs_downstairs_fridge_power`.
- Keep existing names as-is for compatibility; do not normalize unless doing a full migration.

4. Configuration style is mixed old/new in some places.
- Existing automations in this package use legacy keys (`trigger`, `action`, `service`).
- Maintain local style in touched files unless performing deliberate modernization.

## How To Add a New Monitored Device

1. Identify the real power sensor entity ID (W).
2. Decide grouping impact in `power_calcs.yaml`:
- If this device should move from `power_outlets_other` to explicit tracking, subtract it there.
- If it changes category boundaries, update the relevant house group formulas.
3. Add integration counter in `power_energy_counters.yaml`:
- Set `name` to a short human-readable label.
- Set `unique_id` to the full taxonomic slug (`<slug>_energy_counter`).
4. Add utility meters in `power_energy_periods.yaml`:
- Daily and monthly.
- Add TOU tariffs unless this is a non-TOU special case.
5. Add template kWh totals in `power_energy_periods.yaml` (sum peak/shoulder/off-peak where TOU applies).
6. Add template cost sensors in `power_costs.yaml`:
- Daily and monthly.
- Use TOU formula or flat tariff formula per model.
7. Validate with `ha core check` and restart/reload.
8. **Immediately after first load**: verify the counter's entity_id — it will be name-derived (short form). Rename it to `sensor.<unique_id>` (the full slug) via the HA UI or MCP.
9. Verify the counter entity_id now matches the `source:` value in the utility meter config.

## How To Update or Rename Existing Monitoring

1. Treat changes as multi-file refactors; update all pipeline layers.
2. Search for old slug/entity references across:
- `packages/common/power_calcs.yaml`
- `packages/common/power_energy_counters.yaml`
- `packages/common/power_energy_periods.yaml`
- `packages/common/power_costs.yaml`
3. Confirm tariff switch automation regex still includes intended select entities.
4. Validate and check resulting entities in Home Assistant states.

## Validation Checklist

Run:

```bash
ha core check
```

Then verify in HA:

- Counter sensor increments over time.
- Counter `entity_id` is exactly what downstream `utility_meter.source` expects.
- Daily/monthly utility entities exist.
- TOU entities (`*_peak`, `*_shoulder`, `*_off_peak`) appear where expected.
- Template total kWh updates.
- Cost sensors update and reflect tariff switches.

## Guardrails

- Do not edit `.storage` directly.
- Keep entity IDs stable unless intentional migration is planned.
- Prefer additive updates and test each layer before changing formulas heavily.
- When changing names, verify all downstream references before restart.
