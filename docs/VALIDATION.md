# Validation log

Dates: 6–7 October 2026. Xcode 26.3, iOS 26.2 SDK and a dedicated iPhone 17 Pro simulator running iOS 26.3.

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

The bundle ID was registered with the Apple Developer team, and its iCloud/CloudKit and Push Notifications capabilities were enabled and read back through the App Store Connect API. Container association, provisioning and production-schema deployment were subsequently completed during the first TestFlight upload, as described below.

The unsigned Release archive passed at `build/distribution/Fasting-rento.xcarchive`; its built Info.plist confirms `com.rento.fasting`, version 0.1.0, build 1. The start, relaunch, finish and History flow passed with the new identifier in `build/RentoIdentifierVerified.xcresult`. Property-list validation passed, and no previous bundle-identifier references remain in the current source or documentation.

## Last Meal tab

A third tab records when the user finished eating, either with **Just Ate** or a date-and-time picker. Its timer derives from the saved meal time and shows complete days plus hours, minutes and seconds. Meal registrations and corrections do not start or finish a fasting session. Entries have CloudKit-compatible defaults; the latest saved action wins, with a stable UUID tie-break when save times match.

All 22 storage/calculation tests and four new UI flows passed in `build/LastMealFinal.xcresult`. The additional ticking-counter UI check passed in `build/LastMealTickVerified.xcresult`. These checks covered disk reopening, an independently active fast, counter resets, corrections to earlier times, future-date rejection, repeated failed saves, merging order, multi-day durations, English, Spanish and the largest accessibility text size. The original start/relaunch/finish/History flow also passed during this feature's initial validation run.

The database-upgrade test created a store with the original fasting-only schema, then added `MealEntry` and reopened it again. Both the completed multi-day fast and active fast were preserved. A read-only-store test exposed that an insertion could remain visible after a failed SwiftData save and rollback. Meal writes now use a short-lived context, so unsuccessful insertions cannot replace the counter's previously saved record. The repeated-failure check passed with this change.

The final unsigned Release archive passed at `build/distribution/Fasting-last-meal-final.xcarchive`, with bundle ID `com.rento.fasting`. All 117 compiler-extracted strings have English and Spanish translations. The normal clock uses a circular design; accessibility text uses a larger card that allows labels to wrap. Screens were visually reviewed in both languages and at the largest text size.

`FastingDemoCapture.testCaptureThreeTabScreens` passed in `build/readme-20261006-174856/Capture.xcresult`. `scripts/capture_readme.py` captured the current three tabs using isolated sample data, exported named XCTest attachments and regenerated the English three-iPhone cover. The cover now shows History, Fast and Last Meal; the new light and dark screenshots and cover were visually reviewed. The simulator appearance was restored and its status-bar override cleared afterward. The earlier video and GIF still illustrate the Fast and History walkthrough; the README includes separate current Last Meal screenshots.

## Signed distribution and production CloudKit

The App Store Connect record uses bundle ID `com.rento.fasting` and the provisional name **Fasting timer**. The signed Release archive passed at `build/distribution/Fasting-testflight.xcarchive`. App Store distribution export and upload both passed; Apple processed version **0.1.0 (1)** with `processingState = VALID`. Its export-compliance response is saved, and the build is assigned to **Internal Testers** with `internalBuildState = IN_BETA_TESTING`. The author's tester account is invited. English and Spanish testing notes are saved in TestFlight.

The exported package passed strict code-signature verification and uses an App Store provisioning profile with production iCloud and push entitlements. The IPA, signing reports, TestFlight verification report and upload logs are retained in the ignored `build/distribution/` directory. This is an internal beta; no public App Store review submission or external tester group was created.

A signed Debug build was installed on the connected iPhone 15 Pro Max. Running it with `-InitializeCloudKitSchema` generated `CD_FastingSession` and `CD_MealEntry` using a disposable store; the success message and the new record types were observed. CloudKit Console confirmed **Changes Deployed: The schema is deployed to Production** for `iCloud.com.rento.fasting`. The app continues to use the private database.

The source Info.plist declares that the app does not use non-exempt encryption. The app uses Apple-provided storage and networking and contains no custom encryption implementation. The initial uploaded package predates this metadata declaration, so `usesNonExemptEncryption = false` was saved for that build through App Store Connect. An incremental unsigned Release build passed after adding the declaration, and its built Info.plist contains `ITSAppUsesNonExemptEncryption = false`. Property-list validation and `git diff --check` also passed.

## Remaining device validation

Real synchronization between two devices has not been tested. Container registration, signing, schema initialization and production deployment are complete; the remaining check requires two devices using the same Apple Account. The README describes the setup.

Execution on iOS 17–18 and iPad has not been tested in these validation runs. The project declares iOS 17 support, with availability-guarded alternatives to Liquid Glass APIs.
