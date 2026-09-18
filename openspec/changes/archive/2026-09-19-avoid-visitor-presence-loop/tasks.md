## 1. Presence Logic

- [x] 1.1 Move visitor reset from the holiday-light stop automation to a person-arrival automation in the visitor package; verify only that automation lists non-visitor people.

## 2. Validation

- [x] 2.1 Run `ha core check` and verify the configuration is valid.
- [x] 2.2 Enable visitor presence while all other people are away and verify it remains enabled and `group.family` becomes home.
- [x] 2.3 Simulate or observe another person arriving and verify visitor presence becomes disabled.