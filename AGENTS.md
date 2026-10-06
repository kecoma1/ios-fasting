# Working on this app

- This is a native SwiftUI app, based on the conventions in `ios-clipboard`.
- Keep the scope small: a reliable fasting timer and editable history, stored locally with SwiftData and synchronized through private CloudKit.
- Do not add Firebase, analytics, accounts, servers or third-party packages.
- Support iOS 17 and later. Guard iOS 26 Liquid Glass APIs with availability checks and keep native fallbacks.
- Maintain English and Spanish strings in `Fasting/Resources/Localizable.xcstrings`.
- Model properties need defaults or optional values for CloudKit. Do not add unique constraints.
- Do not reset an existing database to recover from initialization errors or silently use in-memory storage.
- Use explicit saves and rollback on failures. A timer must derive its elapsed duration from the stored start date.
- Goals are stored in whole hours and can include days (24 elapsed hours each). Keep the day count visible above the clock for multi-day fasts; reaching a goal must never stop or cap the elapsed duration.
- If files are added or removed, run `python3 scripts/create_project.py` and commit the generated project.
- Validate changes with the relevant storage and UI tests. Use isolated test stores and a dedicated simulator.
- Real iCloud sync needs a provisioned container and signed devices; simulator checks do not verify it.
