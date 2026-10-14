# Session notes

- Remote relay position: `ALWAYS_OFF` left Door inverted (media room relay_1 off, Door sense and remote sense on). `ALWAYS_ON` gives Door = relay_1; all senses then agreed with the relays.
- Media room "Power Status 1 Unconfirmed Switches" read 1 after the first flash: the inverted Door at boot. Resets on reboot (not restored).
- New media room diagnostics got `media_room_media_room_lights_*` entity IDs; the existing ones keep `hallway_hallway_stairs_*` from the board's old name.
- Bug: rebooting the media room turned both lamps off. ESPHome lights queue their restore write in setup and write it on the first loop, after `on_boot` had set the group's ready flag, so the group's restored "off" switched both lamps. Fixed by ignoring the group output's first write.
- A media room reboot still flashes the lamps briefly: the relay pins drop from reset until the restore in setup (mostly bootloader time). Common to these boards; not fixable in firmware.
