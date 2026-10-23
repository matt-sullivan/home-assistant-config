# Garage arrival monitoring

Daily checks for tasks 4.1 and 4.5–4.8 in `tasks.md`. Check once each day until 2026-10-31, then send a final summary. Read-only: don't change any config, automations or phone settings.

Each automation keeps its last 100 traces (a busy day uses ~20), so a missed day is recoverable on the next check.

## Daily checks

Cover the time since the previous daily check.

1. **Garage runs.** Check the traces for `automation.open_garage_when_matt_drives_home` and `automation.open_garage_when_sara_drives_home`.
   - For each run that **finished**, check that the person's tracker (`device_tracker.matt_pixel_8_pro` or `device_tracker.saras_iphone_16`) was `not_home` just before and became `home` within about 2 minutes. Flag any finished run without that arrival, and include its time, trigger and the tracker's `latitude`, `longitude` and `gps_accuracy`.
   - Report any run that passed "Arriving from away" but failed the in-car condition: an arrival on foot or an undetected car. Ask Matt which it was.
   - Report any arrival with two runs less than 2 s apart, and say whether the door got two open commands.
2. **Matt's presence.** List every `home` → `not_home` → `home` change on `device_tracker.matt_pixel_8_pro` where the time away was under 30 minutes. Include the times and the `gps_accuracy` of the `not_home` reading, and ask Matt whether he actually left. Report if either tracker's state was ever `HomeStreet1` or `HomeStreet2`; it never should be.
3. **High accuracy at home.** Report every period when `binary_sensor.pixel_8_pro_high_accuracy_mode` was `on` while Matt's tracker was `home`. Include its start, end and duration.
4. **Battery.** Report how far `sensor.matt_pixel_8_pro_battery_level` dropped on days Matt was home all day. A single number is enough; Matt will judge whether it's normal.
5. **Other openings.** Check `cover.garage_door` history for any opening that has no garage run near it, and mention it as "manual or other".

Report "all clear" if nothing was flagged.

## Final summary

After 2026-10-31, send one summary for the two weeks: arrivals and which trigger opened the door, flagged runs, false aways, high-accuracy-at-home periods, and battery observations.
