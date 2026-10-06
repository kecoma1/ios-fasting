# Validation log

Date: 6 October 2026. Xcode 26.3, iOS 26.2 SDK and a dedicated iPhone 17 Pro simulator running iOS 26.3.

## Initial app

| Check | Result |
| --- | --- |
| Debug build for the simulator | Passed |
| Unsigned Release build for an iOS device | Passed |
| Original 11 storage tests | Passed |
| Start, close, reopen, finish and view history | Passed |
| Add, open, save and delete a past fast | Passed |
| Spanish interface and settings | Passed |
| Visual review in light and dark mode | Passed |
| Start with the largest accessibility text size | Passed |
| Compiler-extracted strings have translations | Passed |
| Opaque 1024 × 1024 app icon | Passed |

Storage checks covered persistence after reopening the database, duplicate active-session prevention, frozen completed durations, date and goal validation, preserving records after invalid edits, persistent edits and deletion, restoring observed values after failed saves, statistics excluding active sessions, durations beyond 24 hours, and CloudKit-compatible defaults.

UI checks led to corrections to the History row's tap area and the start sheet's height with accessibility text. Affected flows were rerun and passed. The full storage suite was rerun after correcting recovery of observed values when a save is rejected.

XCTest results are generated in `build/` and are not committed. Selected real screenshots are in `docs/assets/`.

## Original Spanish recording

`FastingDemoCapture.testCaptureDemo` passed on the dedicated simulator. It used an independent database with three past fasts and an active fast. Sample data is created only in Debug with recording arguments and does not use iCloud.

The original recording is preserved at `docs/demo/fasting-demo-es.mp4`: 118.6 seconds, H.264, 720 × 1566, 30 fps and 3.1 MB. Light and dark frames were reviewed, and the MP4 was decoded successfully. The current recording script defaults to English; `--language es` selects the Spanish walkthrough.

## Multi-day fasts

The original 48-hour goal limit was replaced by a days-and-hours editor, from 1 hour to 365 days. A day is 24 elapsed hours. The timer shows days above `HH:MM:SS` and keeps counting after reaching the goal. History, statistics and editors show complete durations.

`goalHours` remains an integer in SwiftData; the schema and existing records are preserved. Storage checks covered 49 hours, 3 days, 15 days and the editor limit. A fast lasting 3 days, 4 hours and 5 minutes was reopened, completed and reopened again from disk without losing its duration.

All 13 storage tests and six UI flows passed. These covered reopening a multi-day fast, changing goals in Settings, the timer and History, and the goal editor at the largest accessibility text size. The two affected flows were rerun after adding stable confirmation-button identifiers and rebuilding the native hours wheel when its allowed range changes. Both reruns passed. The unsigned Release build for an iOS device also passed.

Results are in `build/MultiDayFinal.xcresult` (storage and five UI flows passed; one goal-test button-selection failure) and `build/MultiDayPickerVerified.xcresult` (both affected flows passed). Selected English examples include `docs/assets/timer-multiday-en.png`, `history-multiday-en.png` and `goal-multiday-en.png`.

## Milestone badges

Six cumulative badges appear below the timer: educational references at 8, 12 and 16 hours, and duration checkpoints at 24, 48 and 72 hours. Each badge opens an explanation, with sources available in the guide. Metabolic timings are approximate; the timer does not confirm ketosis or measure physiological states.

Badges derive from the saved start date without adding SwiftData fields. Checks covered one second before and exactly at each boundary, accumulation across multiple days, reopening storage, editing the start time, frozen completed durations and resetting badges for a new fast.

All 16 storage/calculation tests and four relevant UI flows passed in `build/MilestonesVerified.xcresult`: accumulated badges and relaunch, finishing and starting another fast, all six checkpoints with the Spanish ketone explanation, the largest accessibility text size, and the start/relaunch/finish/History flow. The unsigned iPhone Release build passed, and all 102 compiler-extracted strings have English and Spanish translations.

Badges and explanations were visually reviewed in both languages and with large text. Original selected screenshots remain in `docs/assets/milestones-timer-en.png`, `milestones-multiday-es.png` and `milestones-ketones-es.png`.

## English README and three-iPhone cover

`FastingDemoCapture.testCaptureEnglishDemo` passed on the dedicated simulator in `build/demo-20261006-090246/Capture.xcresult`. The walkthrough uses separate example databases for the ordinary and multi-day fasts and records the current app, including milestone explanations, History, editing, Settings, three-day goals and dark mode.

The new video at `docs/demo/fasting-demo-en.mp4` is 151.4 seconds, H.264, 720 × 1566, 30 fps and 4.9 MB. Its complete decoding passed. The English GIF at `docs/assets/fasting-demo-en.gif` is 18.88 seconds, 360 × 784 and 0.73 MB, with cuts and 1.25× playback.

The README's text, screenshots, cover, GIF and linked walkthrough are in English. Main assets use explicit `-en` filenames. The gallery is exported from named XCTest attachments, and GIF cuts use the recording's timing manifest. Each screenshot was captured at the normal text size with the simulator's status bar set to 9:41; the override was cleared afterward.

`docs/assets/fasting-hero-en.png` follows the `ios-clipboard` cover: three aligned iPhones, a larger center device and a mint/emerald gradient. The screens are real English captures of History, the active timer with badges and a three-day fast in dark mode. AppKit draws the device frames and display cutouts without changing the app interface. The cover and English gallery were visually reviewed, and local README references were checked.

## Rento bundle identifier

The app now uses `com.rento.fasting`; both test targets use the same prefix. The project generator, generated Xcode project, entitlements, persistence configuration and README were updated together. The configured private CloudKit container is `iCloud.com.rento.fasting`.

The bundle ID was registered with the Apple Developer team, and its iCloud/CloudKit and Push Notifications capabilities were enabled and read back through the App Store Connect API. Registering and associating the iCloud container, provisioning and production-schema deployment still require Apple-account setup.

The unsigned Release archive passed at `build/distribution/Fasting-rento.xcarchive`; its built Info.plist confirms `com.rento.fasting`, version 0.1.0, build 1. The start, relaunch, finish and History flow passed with the new identifier in `build/RentoIdentifierVerified.xcresult`. Property-list validation passed, and no previous bundle-identifier references remain in the current source or documentation.

## Still requires Apple-account validation

Real synchronization between devices has not been tested. It requires a registered CloudKit container, signing with the appropriate team, schema initialization and two devices using the same Apple Account. Capabilities, the private-container configuration and initialization command are implemented; the README describes the setup.

Execution on iOS 17–18 and iPad has not been tested in these validation runs. The project declares iOS 17 support, with availability-guarded alternatives to Liquid Glass APIs.
