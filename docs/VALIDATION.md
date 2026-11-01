# Validation

Environment: Xcode 27.0 (27A266a), iPhone 18 Pro simulator with iOS 27.0. Validation date: 2026-10-31.

## Automated

- iOS Simulator Debug build: passed, code signing disabled.
- Foundation policy suite: 4 XCTest cases passed, 0 failures.
- UI integration test: 1 XCTest case passed, 0 failures. Verified initial load, subframe rejection, successful echo, malformed-message rejection, native-to-web delivery, blocked external navigation, and close/reopen.
- Screenshots in `docs/images/` were exported from the successful test run.

The package suite runs on macOS and tests the same policy source compiled into the iOS app. To select the full Xcode toolchain without changing system settings:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift test
```

In Xcode, select a simulator and use Product → Test to run the UI test. It exercises the real bundled page and native bridge. The first test run exposed an interaction synchronization issue; the test now waits for the subframe initialization and a hittable echo button.

## Further manual validation

These checks remain explicit follow-up work, not claimed results:

- Run on a physical iPhone and the minimum supported iOS version.
- Check VoiceOver, large Dynamic Type, dark appearance, iPad layout, and rotation.
- Capture Memory Graph / Instruments evidence across repeated open/close cycles.
- Exercise genuine navigation errors and web-content process termination, then reload.

The app includes error and termination callbacks, but there are no measured memory savings or production reliability claims.
