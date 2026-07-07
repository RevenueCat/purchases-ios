# Paywalls V2 Web View Rebuild Mission

## Mission

Build the Paywalls V2 `web_view` component from `main` as a clean implementation, not as a port of the existing draft stack. The result must render RevenueCat-hosted workflow bundles in `WKWebView`, speak the canonical `@revenuecat/workflow-web-components-sdk` native bridge contract, expose the agreed app-facing RevenueCatUI handler API, and keep the code small enough that one engineer can reason about a full web view session in one place.

The implementation should be functionally complete for v1 while avoiding the accidental complexity from the earlier stack:

- no `window.RevenueCatWebView` shim
- no `rcWebViewMessage` handler
- no `rcWebViewHeight` handler
- no injected height-measurement script
- no split parser/dispatcher/bridge state machine
- no URL template substitution
- no local bundle cache or custom URL scheme
- no separate iOS and macOS copies of the same representable logic

## Product behavior

Dashboard-authored paywalls may include a component:

```json
{
  "type": "web_view",
  "id": "survey-step",
  "name": "Survey step",
  "visible": true,
  "url": "https://<digest>.components.revenuecat-static.com/index.html",
  "protocol_version": 1,
  "size": { "width": { "type": "fill" }, "height": { "type": "fit" } },
  "fallback": { "type": "stack", "components": [] }
}
```

The SDK loads the literal HTTPS `url` in a non-persistent `WKWebView`. The URL is static: it is not localized, templated, or resolved against dashboard custom variables. Runtime variables flow only through the bridge.

If the component is invisible, invalid, unsupported, blocked by content isolation setup failure, or fails a determined main-frame load, RevenueCatUI renders the component's decoded generic `fallback` when present. If no fallback exists, it renders nothing.

## Canonical wire contract

The injected bundle SDK detects iOS by checking:

```javascript
typeof window.webkit?.messageHandlers?.rcWebComponents?.postMessage === "function"
```

Therefore the native host must register the `WKScriptMessageHandler` name `rcWebComponents`. Content sends JSON strings to that handler:

```javascript
window.webkit.messageHandlers.rcWebComponents.postMessage(JSON.stringify(envelope))
```

Native sends JSON objects back by evaluating:

```javascript
if (typeof window.__rcWebComponentsReceive === 'function') {
  window.__rcWebComponentsReceive(envelope)
}
```

Every frame uses this envelope:

```json
{
  "channel": "rc-web-components",
  "protocol_version": 1,
  "kind": "connect | init | reject | message | request | response | error",
  "component_id": "survey-step",
  "type": "rc:step-complete",
  "id": "request-123",
  "payload": {},
  "error": "error message"
}
```

Rules:

- Drop envelopes with any channel other than `rc-web-components`.
- Support protocol version `1` only.
- Content opens the bridge with `kind: "connect"`. The native host answers with `kind: "init"` on version match or `kind: "reject"` on mismatch.
- Ignore app messages until the handshake opens the channel.
- `kind: "request"` requires an `id`; auto-replies must echo the same `id` and `type`.
- Inbound JSON string size limit is 65,536 bytes.
- Decoded payload nesting depth limit is 16.
- Once open, all inbound app envelopes must match the component id.
- Outbound and inbound app traffic is allowed only while the web view's current main-frame origin matches the component URL's origin.
- Host comparison is case-insensitive and default ports are normalized.

### App-facing message set

Native recognizes these v1 app message types:

| Type | Direction | Behavior |
| --- | --- | --- |
| `resize` | content to native | Internal only. Update measured content size for axes whose schema size is `fit`. Do not deliver to the app handler. |
| `rc:step-loaded` | content to native | Deliver `PaywallWebViewMessage.stepLoaded` to the app handler. |
| `rc:step-complete` | content to native | Deliver `PaywallWebViewMessage.stepComplete(responses:)`; read responses from `payload.responses` when present, else use the payload object without reserved keys. |
| `rc:request-variables` | content to native | Always auto-reply with SDK variables. Then deliver the request message to the app handler. |
| `rc:error` | content to native | Deliver an error message when `payload.error` or `error` contains a string. |
| `rc:variables` | native to content | Sent by SDK auto-replies and `PaywallWebViewController.postVariables`. Payload is the flat variables map. |
| `fit` | native to content | Sent immediately after `init` when either axis uses `fit`; payload includes only host-managed axes, for example `{ "height": true }`. |

The variables payload is flat:

```json
{
  "channel": "rc-web-components",
  "protocol_version": 1,
  "kind": "message",
  "component_id": "survey-step",
  "type": "rc:variables",
  "payload": { "locale": "en-US" }
}
```

It is never nested under a `variables` key.

## Simplified architecture

The implementation should have one owner for each responsibility.

### Core schema

Create `PaywallComponent.WebViewComponent` in `Sources/Paywalls/Components/PaywallWebViewComponent.swift`.

Responsibilities:

- decode and encode `type: "web_view"`
- hold static component data: `id`, `name`, `visible`, `url`, `protocolVersion`, `size`, visual chrome, overrides, and generic fallback
- require `url` to be a literal string from the backend; URL validation belongs in the view model
- participate in `PaywallComponent` encode/decode and hashing
- be skipped by cache warming because the bundle is rendered from its remote origin

### Public RevenueCatUI API

Keep the public API shape deliberately small and SwiftUI-native:

- `PaywallWebViewValue`: a public struct wrapper around JSON values, not a public enum.
- `PaywallWebViewMessage`: a public struct with static constructors or static constants for known message types, not a public enum.
- `PaywallWebViewController`: a public final class or struct that weakly wraps the active session and can post `rc:variables` or arbitrary app messages.
- `View.onPaywallWebViewMessage(_:)`: a public SwiftUI modifier that stores a handler in the environment.

Do not add purchase, restore, dismiss, navigate, or dashboard-custom-variable bridge APIs in v1.

### Web view session

Create one `@MainActor` class that owns the session:

```swift
@MainActor
final class WebViewSession: NSObject, ObservableObject, WKScriptMessageHandler, WKNavigationDelegate {
    let componentID: String
    let protocolVersion: Int
    let componentURL: URL
    let componentOrigin: WebViewOrigin
    let size: PaywallComponent.Size

    @Published private(set) var measuredSize: CGSize?
    @Published private(set) var loadFailed: Bool

    var messageHandler: PaywallWebViewMessageAction?
    var evaluateJavaScript: (String) -> Void

    private var channelOpen: Bool

    func start(in webView: WKWebView)
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage)
    func postVariables(_ variables: [String: PaywallWebViewValue])
    func postMessage(type: String, payload: [String: PaywallWebViewValue])
}
```

The exact stored properties may vary, but the ownership must not: handshake state, origin gating, fit sending, resize handling, variables replies, app-message dispatch, outbound JavaScript generation, navigation policy, and load-failure state all belong to this session object.

This deletes the need for separate bridge, bridge-host, bridge-configuration, parser, and dispatcher types. Tests construct `WebViewSession` directly with injected closures and feed it raw JSON strings.

### Envelope and values

Create `WebViewEnvelope.swift` as a small Codable wire model:

```swift
struct WebViewEnvelope: Codable, Equatable {
    enum Kind: String, Codable {
        case connect, init, reject, message, request, response, error
    }

    var channel: String
    var protocolVersion: Int
    var kind: Kind
    var componentID: String
    var type: String?
    var id: String?
    var payload: PaywallWebViewValue?
    var error: String?
}
```

Use coding keys for `protocol_version` and `component_id`. Use `JSONDecoder` and `JSONEncoder` instead of ad hoc dictionaries. Keep the size and nesting-depth checks explicit.

### Isolation

Create `WebViewIsolation.swift`.

Responsibilities:

- compile the `WKContentRuleList` once
- block third-party `image`, `script`, `font`, and `raw` loads
- allow same-origin subresources and same-origin fetch/XHR
- allow `data:` images and fonts
- fail closed: if rule compilation fails, do not load the web view

The rule-list identifier must include the policy version, for example `rc-webview-v2-isolation`.

### Rendering

Create `RevenueCatUI/Templates/V2/Components/WebView/`.

Suggested files:

- `WebViewComponentViewModel.swift`: resolves visible/style state and validates the literal HTTPS URL.
- `WebViewComponentView.swift`: SwiftUI view, measured-size state, fallback rendering, and visual modifiers.
- `WebViewRepresentable.swift`: one file with shared coordinator/session code and small `#if os(macOS)` / `#else` protocol conformances.

The view owns the session with `@StateObject` and uses SwiftUI identity to manage lifecycle:

```swift
.id("\(viewModel.componentID)|\(url.absoluteString)")
```

When URL or component id changes, SwiftUI creates a new web view and a new session. Do not manually reuse a session across URLs.

Sizing has one path:

```text
content SDK resize message -> WebViewSession.measuredSize -> SwiftUI frame -> existing size modifier/chrome
```

Do not use `WKWebView.intrinsicContentSize` or injected measurement scripts.

## Navigation and origin policy

The web view may load only the component URL's origin in the main frame. `WKNavigationDelegate` should cancel main-frame navigations to any other origin. Subresource blocking is handled by the rule list.

Defense-in-depth origin checks remain in the session:

- inbound app messages are ignored if the web view has navigated away from the component origin
- outbound deliveries are dropped if the current origin does not match

Because cross-origin main-frame navigation is blocked, those checks should be simple and rarely exercised.

## Failure and fallback behavior

Render fallback when any of these is true:

- URL validation fails
- protocol version is unsupported
- content rule list compilation fails
- main-frame navigation receives HTTP status 400 or higher
- main-frame navigation fails with a non-benign error

Do not render fallback for user cancellations or benign navigation interruptions.

When no fallback exists, render `EmptyView`.

## Non-goals

- local bundle caching
- rendering from `file://`, custom schemes, or app assets virtual hosts
- URL variable substitution
- sending dashboard custom variables automatically
- purchase, restore, dismiss, or navigate bridge messages
- hybrid SDK work
- adding new public enums
- tvOS support for the web view component

## Definition of done

The rebuild is complete only when all of these are true:

- `PaywallComponent` decodes and encodes `type: "web_view"` with `protocol_version: 1`.
- Invalid web view URLs render fallback or nothing and never start a web view load.
- The implementation registers exactly one content bridge handler, `rcWebComponents`.
- Native-to-content delivery uses `window.__rcWebComponentsReceive`.
- The legacy names `rcWebViewMessage`, `rcWebViewHeight`, `RevenueCatWebView`, and `__revenueCatReceiveMessage` do not appear in Swift sources.
- The bridge performs `connect` to `init` / `reject` handshake and drops app frames before `init`.
- `rc:request-variables` auto-replies without requiring an app handler.
- Variables payloads are flat maps.
- `fit` is sent after `init` for host-managed axes.
- `resize` updates SwiftUI sizing and is not delivered to app code.
- Main-frame cross-origin navigation is blocked.
- Content isolation allows same-origin resources and blocks third-party resources.
- Isolation failure fails closed.
- Main-frame load failure renders generic fallback when available.
- Public API testers cover new RevenueCatUI API.
- `api/revenuecatui-api-*.swiftinterface` baselines are regenerated if public API changes.
- Unit tests cover schema, URL validation, envelope decoding, value decoding, handshake, variables, fit, resize, origin gating, navigation policy, isolation, and fallback.
- A focused RevenueCatUI test target run passes locally or CI evidence is attached to the PR.
- SwiftLint passes.

## Suggested implementation loop

Agents implementing this mission should use the companion implementation plan in:

`docs/superpowers/plans/2026-07-07-paywall-web-view-rebuild.md`

Work one task at a time:

1. write or update the failing test named in the plan
2. run the exact focused test command
3. implement the smallest production slice
4. run the focused test again
5. run the task's acceptance searches
6. commit

Do not advance to a later task while a focused test from the current task is failing.
