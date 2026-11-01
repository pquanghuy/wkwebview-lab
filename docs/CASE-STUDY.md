# A small native–web boundary

## Problem

A web view becomes harder to reason about when every frame can invoke native methods, message bodies are loosely typed, replies are assembled as executable strings, and handlers outlive their screen.

This demo isolates these failure modes in a local fixture. It makes no claims about improvements in a production application.

## Design

The SwiftUI screen owns a session. The session owns a WKWebView, navigation policy, and message handler. The user-content controller also retains the handler, so the event callback captures the session weakly. UIViewRepresentable dismantling explicitly removes the handler and clears delegates.

The document URL and main-frame flag are checked before parsing a bridge request. A small pure policy module validates version, action, and UTF-8 payload size. JavaScript gets either a structured result or a rejected promise. Native-to-web calls pass values through the arguments dictionary rather than interpolating source strings.

The navigation delegate allows the main bundled document and a specific local subframe fixture. It rejects remote and new-window requests. The subframe exists to demonstrate that permission to render content does not imply permission to call native code.

## Tradeoffs

- Bundled content keeps the experiment deterministic but does not model server authentication or redirects.
- The page world is convenient for a controlled fixture; isolating injected code requires a separate design for remote content.
- An echo API is intentionally limited. Each additional capability needs its own schema and authorization rules.
- Nonpersistent storage reduces retained browsing state but is not a complete privacy or security guarantee.
- Deallocation logging is an observation aid, not proof that WebKit processes have returned all memory. Use Instruments and the Memory Graph for lifecycle investigation.

## Evidence

See VALIDATION.md. There are no invented latency, memory, crash-rate, or production-impact figures.
