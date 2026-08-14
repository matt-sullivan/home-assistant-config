# Power Monitoring Companion Templates

Use these snippets as a quick starting point when adding a new monitored power device or group.

How to use this file:

1. Choose a canonical slug (examples: `power_outlet_kitchen_toaster`, `power_house_solar`).
2. Replace all placeholder tokens consistently.
3. Add snippets in the listed files and keep IDs aligned across layers.
4. Validate with `ha core check`.

Placeholder tokens:

- `<slug>`: canonical slug for this monitored item
- `<power_source_entity_id>`: source power sensor in W (must exist)
- `<title>`: human-friendly display name

## 1) Optional Power Calc Template

File: `packages/common/power_calcs.yaml`

Use this only when you need a derived power sensor from one or more other sensors.

```yaml
template:
  - sensor:
      - name: "Power - <title>"
        unique_id: <slug>
        default_entity_id: sensor.<slug>
        unit_of_measurement: "W"
        device_class: power
        state_class: measurement
        state: >
          {{ (
            states('<power_source_entity_id>') | float(0)
          ) | round(3) }}
```

If this is a residual bucket, use subtraction pattern:

```yaml
state: >
  {{ (
    states('sensor.<parent_power_sensor>') | float(0)
    - states('sensor.<known_child_1_power>') | float(0)
    - states('sensor.<known_child_2_power>') | float(0)
  ) | round(3) }}
```

## 2) Integration Counter Template

File: `packages/common/power_energy_counters.yaml`

```yaml
sensor:
  - platform: integration
    source: sensor.<slug>
    name: "<title> Energy Counter"
    unique_id: <slug>_energy_counter
    unit_prefix: k
    round: 2
    max_sub_interval:
      minutes: 5
```

If your source is not `sensor.<slug>`, point `source` to the true power sensor entity.

## 3) Utility Meter Templates

File: `packages/common/power_energy_periods.yaml`

TOU version (most entities):

```yaml
utility_meter:
  <slug>_energy_daily:
    source: sensor.<slug>_energy_counter
    cycle: daily
    tariffs:
      - peak
      - shoulder
      - off-peak

  <slug>_energy_monthly:
    source: sensor.<slug>_energy_counter
    cron: "0 0 26 * *"
    tariffs:
      - peak
      - shoulder
      - off-peak
```

Non-TOU version (hot-water style):

```yaml
utility_meter:
  <slug>_energy_daily:
    source: sensor.<slug>_energy_counter
    cycle: daily

  <slug>_energy_monthly:
    source: sensor.<slug>_energy_counter
    cron: "0 0 26 * *"
```

## 4) Template Energy Totals

File: `packages/common/power_energy_periods.yaml`

TOU total sensor templates:

```yaml
template:
  - sensor:
      - name: <slug>_energy_daily
        unique_id: <slug>_energy_daily
        device_class: energy
        state_class: total
        unit_of_measurement: kWh
        state: >
          {{
            (
              (states("sensor.<slug>_energy_daily_peak") | float(0))
              + (states("sensor.<slug>_energy_daily_shoulder") | float(0))
              + (states("sensor.<slug>_energy_daily_off_peak") | float(0))
            ) | round(3)
          }}

      - name: <slug>_energy_monthly
        unique_id: <slug>_energy_monthly
        device_class: energy
        state_class: total
        unit_of_measurement: kWh
        state: >
          {{
            (
              (states("sensor.<slug>_energy_monthly_peak") | float(0))
              + (states("sensor.<slug>_energy_monthly_shoulder") | float(0))
              + (states("sensor.<slug>_energy_monthly_off_peak") | float(0))
            ) | round(3)
          }}
```

For non-TOU entities, utility meters already provide totals directly and you usually do not need these sum templates.

## 5) Cost Sensor Templates

File: `packages/common/power_costs.yaml`

TOU cost templates:

```yaml
template:
  - sensor:
      - name: <slug>_cost_daily
        unique_id: <slug>_cost_daily
        unit_of_measurement: "$"
        device_class: monetary
        state: >
          {{
            (((states("sensor.<slug>_energy_daily_peak") | float(0)) * (states("input_number.power_tariff_peak_c_per_kwh") | float(0)))
            + ((states("sensor.<slug>_energy_daily_shoulder") | float(0)) * (states("input_number.power_tariff_shoulder_c_per_kwh") | float(0)))
            + ((states("sensor.<slug>_energy_daily_off_peak") | float(0)) * (states("input_number.power_tariff_off_peak_c_per_kwh") | float(0))))
            / 100
          | round(2) }}

      - name: <slug>_cost_monthly
        unique_id: <slug>_cost_monthly
        unit_of_measurement: "$"
        device_class: monetary
        state: >
          {{
            (((states("sensor.<slug>_energy_monthly_peak") | float(0)) * (states("input_number.power_tariff_peak_c_per_kwh") | float(0)))
            + ((states("sensor.<slug>_energy_monthly_shoulder") | float(0)) * (states("input_number.power_tariff_shoulder_c_per_kwh") | float(0)))
            + ((states("sensor.<slug>_energy_monthly_off_peak") | float(0)) * (states("input_number.power_tariff_off_peak_c_per_kwh") | float(0))))
            / 100
          | round(2) }}
```

Flat tariff cost templates (hot-water style):

```yaml
template:
  - sensor:
      - name: <slug>_cost_daily
        unique_id: <slug>_cost_daily
        unit_of_measurement: "$"
        device_class: monetary
        state: >
          {{
            (((states("sensor.<slug>_energy_daily") | float(0))
            * (states("input_number.power_tariff_hot_water_c_per_kwh") | float(0))) / 100)
            | round(2)
          }}

      - name: <slug>_cost_monthly
        unique_id: <slug>_cost_monthly
        unit_of_measurement: "$"
        device_class: monetary
        state: >
          {{
            (((states("sensor.<slug>_energy_monthly") | float(0))
            * (states("input_number.power_tariff_hot_water_c_per_kwh") | float(0))) / 100)
            | round(2)
          }}
```

## 6) Optional Tariff Automation Filter Check

File: `packages/common/power_costs.yaml`

If using TOU utility meters, confirm your new meter select entities match the existing selector regex:

```yaml
| select('match', '^select\\.power_.*_energy_(daily|monthly)$')
| reject('search', '_hot_water_')
```

If your slug does not start with `power_`, your tariff select may not be auto-switched.

## 7) Copy-Paste Checklist

1. Add or adjust power source in `power_calcs.yaml` if needed.
2. Add integration counter.
3. Add daily and monthly utility meters.
4. Add TOU energy total templates if using tariffs.
5. Add daily and monthly cost templates.
6. Update residual bucket formulas when carving out a device from `other`.
7. Run `ha core check`.
8. Verify entities in HA state UI.
