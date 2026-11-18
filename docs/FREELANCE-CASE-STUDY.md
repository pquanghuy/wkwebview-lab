# WKWebView — Native–Web Boundaries and Lifecycle

[Source and demo](https://github.com/pquanghuy/wkwebview-lab)

## Problem
A native–web bridge needs clear rules about who may call it, what data is accepted, and when retained handlers are released.

## Implementation
The SwiftUI screen owns a web session. Requests require the exact bundled main document and main frame, a supported version/action, and a text payload within a UTF-8 byte limit. Structured replies and JavaScript argument passing keep message values out of executable source strings. Navigation rejects external/new-window requests. Weak callback capture and explicit handler/delegate removal make ownership inspectable.

## Evidence
The existing validation record reports four policy tests and one simulator UI integration test passing on 2026-10-31, Xcode 27.0 / iOS 27.0. Integration covers echo, malformed messages, subframe rejection, native-to-web delivery, blocked navigation and close/reopen. These tests were not rerun while preparing this case study.

## Tradeoffs and limits
Bundled content makes the lab deterministic. It does not demonstrate remote authentication, cookies, downloads or a production browser. Deallocation logging is not proof of WebKit process memory reclamation. No measured speedup, RAM reduction or production crash improvement is claimed. Physical-device, minimum-OS and repeated lifecycle profiling remain follow-up work.

## Client relevance
Useful evidence for a scoped WKWebView bridge, navigation or lifecycle investigation. Remote content needs its own origin and capability policy.

## Run
Open WKWebViewLab.xcodeproj, choose WKWebViewLab and an iOS simulator. Send an echo, malformed payload and subframe request; close and reopen. Product → Test runs the UI suite; the README documents the policy suite command.

[Validation](https://github.com/pquanghuy/wkwebview-lab/blob/main/docs/VALIDATION.md) · [Design case study](https://github.com/pquanghuy/wkwebview-lab/blob/main/docs/CASE-STUDY.md)

Independent sample code; no employer code or customer data.
