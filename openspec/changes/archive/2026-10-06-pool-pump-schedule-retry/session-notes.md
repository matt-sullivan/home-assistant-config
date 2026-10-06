# Session notes

- Plug powered off: Tuya marks it `unavailable` after ~2–3 min; after power-on it is back within ~1 min and its relay comes back on (it was on before; always-on vs restore-last undetermined).
- While `unavailable`, HA skips `switch.turn_*` with a warning ("Referenced entities ... not currently available") instead of calling Tuya, so offline-plug tests don't exercise the Tuya exception path. Sending a command in the 2–3 min before Tuya marks the plug offline should.
- 2026-10-05 test run: attempts at 15:36:05, 15:37:05, 15:38:05 (unavailable, skipped); plug back 15:38:49 (on); attempt at 15:39:05 turned it off and the run ended with no notification.
- Unplugged but before Tuya marked it offline (15:40:17, 15:41:17), `switch.turn_off` reached Tuya and returned no error; the command was silently undelivered. State verification still caught it. The Tuya exception path (as on 2026-09-15) was not reproduced.
- 15:42:45 `target: on` restarted the off run (2.7); 10 attempts 15:42:45–15:51:45, then `notify.admins` "Pool pump failed to turn on" at 15:52:45 (2.6).
- 2026-10-05 16:00 scheduled off, during an intermittent internet outage (~15:30–22:00): all 10 attempts raised `HTTPSConnectionPool(host='apigw.tuyaeu.com') Max retries` in `pool_pump_command`; the loop continued (Tuya exception path verified). The `notify.admins` call at 16:10 failed to reach the phone (mobile_app push needs internet). Pump stayed on until turned off from a browser session of the user's account at 21:42.
- 2026-10-06 10:00 scheduled on: succeeded on the first attempt.
- 2026-10-06 2.5: plug unavailable 12:09:19; `target: on` run 12:09:21 with skipped attempts each minute (last 12:13:21); plug powered up on at ~12:13:34 and the run ended immediately with no further command or notification.
