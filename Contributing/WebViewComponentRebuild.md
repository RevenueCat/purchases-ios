# Mission: rebuild the Paywalls V2 `web_view` component from scratch

**Audience:** an autonomous coding agent working in this repository (`RevenueCat/purchases-ios`), starting from `main`.
**Goal:** a functionally complete `web_view` component that is materially simpler than the prototype PR stack it replaces: fewer types, one owner for session state, exactly two explicit test seams (§4.2), one sizing path. Where any summary phrasing in this document conflicts with a numbered section, **the numbered section is authoritative**.
**You are done when every box in [Definition of done](#definition-of-done) is checked and the [verification loop](#verification-loop) is green.**

---

## 1. Mission summary

Paywalls V2 paywalls can embed a `web_view` component: an RC-hosted, self-contained web bundle rendered inline inside the native paywall, speaking a versioned postMessage-style protocol with the native host. A prototype exists as an unmerged PR stack (see [References](#9-references)) that works but is over-decomposed: session state is spread across ~8 collaborating types, there are two duplicated platform representables, three stacked sizing mechanisms, and a hand-rolled `[String: Any]` parsing layer.

You will re-implement the feature on top of `main` with the target architecture in §4. **The wire protocol (§3), schema (§2), public API (§5), and security posture (§6) are fixed contracts — implement them exactly. The internal architecture is where you simplify.**

Do NOT copy files wholesale from the prototype branches. Port the *contracts and tests*, write the implementation fresh against the architecture below. You MAY read the prototype branches at any time to resolve ambiguity about intended behavior.

### Hard constraints

- Swift, iOS 15+ / macOS 12+ availability annotations (`@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)`), matching how other Paywalls V2 components are annotated.
- tvOS: excluded (`#if !os(tvOS)`). watchOS: no WebKit — component renders nothing (`EmptyView`).
- No new third-party dependencies.
- No purchase/restore/dismiss message types. No dashboard custom variables over the bridge. No bundle caching or offline rendering. No feature flags. No fallback-component rendering on load failure (§4.5).
- Follow `Contributing/SwiftStyleGuide.swift` and keep SwiftLint clean.

---

## 2. Schema contract (fixed)

New component type in the core SDK (`Sources/Paywalls/Components/`):

| JSON key | Swift | Type | Rules |
|---|---|---|---|
| `type` | — | `"web_view"` | discriminator; add `ComponentType.webView = "web_view"` |
| `id` | `id` | `String?` | optional. Doubles as the bridge `component_id`. **No `id` ⇒ bridge disabled** (render-only). |
| `name` | `name` | `String?` | optional |
| `visible` | `visible` | `Bool?` | optional; treat `nil` as `true` |
| `protocol_version` | `protocolVersion` | `Int` | optional in JSON, **default `1`** when absent. Decoded and preserved, but **not** used as the host's capability: the host's supported version is the hard-coded constant `1` (§3). |
| `url` | `url` | `String` | required. A **literal, static HTTPS URL** — never a template. No variable substitution anywhere. |
| `size` | `size` | `PaywallComponent.Size` | optional; default `width: .fill, height: .fit` |

Exact naming and access, matching the prototype: the type is `PaywallComponent.WebViewComponent` (a `final class` in `Sources/Paywalls/Components/PaywallWebViewComponent.swift`) and is **`@_spi(Internal) public`** — NOT plain `public`. Copy the declaration shape, initializer, and access level from branch `web-view-bridge-wiring` verbatim; only the doc comments may be improved. Decoding relies on `JSONDecoder.default`'s snake_case key strategy like the other component types — follow whichever convention the sibling components in that folder use rather than inventing CodingKeys.

Decoding must tolerate unknown keys (forward compatibility). Wire the new case into:

- `PaywallComponent` enum encode/decode (`PaywallComponentBase.swift` et al.).
- `ViewModelFactory` → produce the view model (§4).
- `PaywallV2CacheWarming`: `web_view` contributes **no** image/video URLs (add to the skip branches).
- `PresentedPartials` / `containsUnsupportedConditions` equivalents: `web_view` is never an "unsupported condition".

---

## 3. Wire protocol contract (fixed — this is external, do not improvise)

The content side is the injected `window.RC` from `@revenuecat/workflow-web-components-sdk`. Android (`purchases-android` branch `alexrepty/paywalls-web-view-bridge`, file `WebViewJavaScriptBridge.kt`) implements the same native-host contract; mirror its semantics when in doubt.

### Names (exact strings)

- `WKScriptMessageHandler` name: **`rcWebComponents`**. The content SDK detects iOS by probing `window.webkit.messageHandlers.rcWebComponents.postMessage`. Inbound bodies are JSON **strings** (accept a dictionary body defensively, but the string path is primary).
- Native → JS: `webView.evaluateJavaScript("(function(){var m=<json>;if(typeof window.__rcWebComponentsReceive==='function'){window.__rcWebComponentsReceive(m);}})();")`. JSON built by an encoder, never by string interpolation of values; escape `\u{2028}`/`\u{2029}` after encoding.
- Do **not** inject any bridging user script (no `window.RevenueCatWebView`, no receive-function shims). The content SDK owns its side.

### Envelope (every frame, both directions)

```json
{
  "channel": "rc-web-components",
  "protocol_version": 1,
  "kind": "connect | init | reject | message | request | response | error",
  "component_id": "<string; \"\" allowed only on connect>",
  "type": "<app message name — on message/request/response>",
  "id": "<correlation id — on request/response/error>",
  "payload": {},
  "error": "<string — on error/reject>"
}
```

Drop silently (debug log only): wrong/missing `channel`, unknown `kind`, non-JSON body, malformed fields.

### Handshake

1. Content sends `kind:"connect"` with its `protocol_version` (`component_id` may be `""`). It retries until answered.
2. **The host's supported protocol version is the hard-coded constant `1`** (`WebViewEnvelope.defaultProtocolVersion`) — NOT the schema's decoded `protocolVersion`. Rationale: the envelope version is the wire+SDK major the content speaks; this SDK build implements exactly v1, so it must never accept a handshake for a version it cannot service, even if a future schema declares one. (Known deviation from the current Android prototype, which uses the schema value — do not copy that.) If `envelope.protocol_version == 1`: mark channel **open**, reply `kind:"init"` with the real `component_id`.
3. Else reply `kind:"reject"`, `component_id:""`, `error:"Unsupported protocol_version N; native host supports 1"`. Channel stays closed.
4. Immediately after `init`, if either size axis is `fit`, send the `fit` message (below).
5. All `message`/`request` frames received while the channel is closed are dropped (debug log).
6. A duplicate `connect` while open is ignored (matches Android).

### App messages, web → native (v1)

| `type` | Rules |
|---|---|
| `rc:step-loaded` | no payload |
| `rc:step-complete` | responses map = `payload.responses` if present; else the whole `payload` if it contains no envelope-reserved keys (`channel`, `protocol_version`, `kind`, `type`, `component_id`, `id`, `error`, `variables`); missing payload ⇒ empty. Malformed ⇒ drop the message. |
| `rc:request-variables` | **auto-replied by the SDK even with no app handler** (below), then forwarded to the app handler |
| `rc:error` | error string from `payload.error` (fallback: top-level `error`); required, else drop |
| `resize` | **SDK-internal** — handled for `fit` sizing (§7), NEVER forwarded to the app handler, regardless of `kind` |
| anything else | drop with debug log (v1 policy) |

Valid app messages are delivered to the app handler as `PaywallWebViewMessage` on the main actor.

### `rc:request-variables` auto-reply

- Arrived as `kind:"request"` with `id` → reply `kind:"response"`, **same `id`, same `type`**, `payload` = variables map. A `request` without `id` is dropped.
- Arrived as `kind:"message"` → send `kind:"message"`, `type:"rc:variables"`, `payload` = variables map.
- **The variables map goes directly into `payload` — flat, NOT nested under a `variables` key.** SDK-managed variables in v1 are exactly `{"locale": "<BCP-47 tag>"}` (e.g. `en-US`; hyphens, never underscores). `locale` is reserved: strip it from app-provided maps with a warning log.

### Native → web (app-initiated)

`PaywallWebViewController.postVariables` → `kind:"message"`, `type:"rc:variables"`, payload = sanitized map. `postMessage(componentID:type:variables:)` → `kind:"message"`, given `type`, payload = map. Outbound frames are only delivered while the channel is open and the origin check (§6) passes.

### `fit` / `resize` sizing messages

- Host → content `type:"fit"`, `kind:"message"`, payload declaring the axes the host manages — `{"width": true}` and/or `{"height": true}`, exactly the axes whose schema size is `fit`. Sent once after `init`; omit the message entirely when neither axis is `fit`. **Declare an axis if and only if the host applies resizes on that axis** (declaring makes the content suppress its scrollbar there; declaring without applying would strand the content with neither scrolling nor fitting).
- Content → host `type:"resize"`, payload `{"width": <px>, "height": <px>}` (either axis may be absent). Validate per axis: finite, > 0; clamp to **10,000**; ignore invalid values; apply only to axes whose schema size is `fit`; ignore changes smaller than **1 pt** against the last applied value (guards against sub-pixel churn and report/apply feedback loops — width especially, since HTML content's reported width often just echoes the imposed viewport width).

### Limits

- Max inbound frame size: **65,536 bytes** (serialized JSON).
- Max JSON nesting depth: **16**.
- Initial placeholders for `fit` axes until the first valid `resize`: **100 pt** height, **300 pt** width (§7).
- Resize apply threshold: ignore per-axis changes < **1 pt** against the last applied value (§7).

---

## 4. Target architecture (this is the point of the rebuild)

Six production files under `RevenueCatUI/Templates/V2/Components/WebView/` (plus the schema file in `Sources/`). Keep the total production footprint in the neighborhood of **900 lines**; if you exceed ~1,200 you are re-growing the prototype's complexity — stop and reconsider.

### 4.1 `WebViewEnvelope.swift` (~120 lines)

`Codable` wire model. `struct Envelope: Codable` with a `Kind: String, Codable` enum and snake_case CodingKeys. Make `PaywallWebViewValue` `Codable` so `payload: [String: PaywallWebViewValue]?` decodes directly — **there must be no `[String: Any]` traffic anywhere**. Inbound: check byte size first, then `JSONDecoder().decode`, then one recursive depth check (≤ 16) on the payload tree. Outbound: `JSONEncoder` → string → escape U+2028/U+2029 → wrap in the guarded receive call. Constants (`channel`, handler name, receive function, message type strings, limits) live here.

### 4.2 `WebViewSession.swift` (~250 lines) — the single owner

```swift
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class WebViewSession: NSObject, WKScriptMessageHandler {
    let componentID: String          // schema id; session only exists when non-nil
    let protocolVersion: Int
    let expectedOrigin: String       // computed once from the component URL (§6)
    var messageHandler: PaywallWebViewMessageAction?   // updated on body changes
    var onContentResize: (@MainActor (CGFloat?, CGFloat?) -> Void)?
    private(set) var channelOpen = false

    // THE test seams (exactly two, both defaulting to webView-backed closures in production):
    // outbound delivery, and the web view's current URL for delivery-time origin checks.
    // `postVariables`/`post` MUST re-check the origin via `currentURL()` at delivery time —
    // do NOT hold a WKWebView reference on the session for this.
    var evaluateJavaScript: (String) -> Void
    var currentURL: () -> URL?

    let fitAxes: (width: Bool, height: Bool)

    func handle(rawMessage: Any, isMainFrame: Bool, currentURL: URL?)
    func postVariables(componentID: String, variables: [String: PaywallWebViewValue])
    func post(componentID: String, type: String, variables: [String: PaywallWebViewValue])
}
```

Everything protocol-related lives here: envelope decode, handshake (`connect`/`init`/`reject`), duplicate-connect ignore, `fit` send, channel gating, component-id check, origin check (inbound *and* outbound), `resize` interception, `rc:request-variables` auto-reply, app-handler dispatch, outbound delivery, all limit enforcement, all rejection logging. `WKScriptMessageHandler` conformance extracts (`body`, `frameInfo.isMainFrame`, `webView?.url`) and calls `handle(...)` — so the full logic is testable headlessly by calling `handle` with a JSON string and asserting on captured outbound JS. Register on the user content controller through a small `WeakScriptMessageHandler` shim (WKUserContentController retains handlers strongly — port this one helper from the prototype).

Concurrency note (a known compiler trap): `WKScriptMessageHandler.userContentController(_:didReceive:)` is a nonisolated protocol requirement, while the session is `@MainActor`. WebKit invokes it on the main thread, so implement the conformance as a `nonisolated` method that hops in via `MainActor.assumeIsolated { ... }` (or an equivalent pattern already used in this codebase). Do not weaken the session's `@MainActor` isolation to satisfy the conformance, and do not use `DispatchQueue.main.async` (it would reorder against synchronous test calls).

There is NO separate parser type, dispatcher type, bridge-host protocol, or bridge-configuration struct. There is no per-message controller construction: the public `PaywallWebViewController` holds `weak var session: WebViewSession?` and forwards its two methods.

### 4.3 `WebViewIsolation.swift` (~60 lines)

The content-blocking policy and an async compile cache:

```swift
enum WebViewIsolation {
    static let contentRuleListIdentifier = "rc-webview-v2-isolation"
    static var contentBlockingRules: String? { ... }   // exact JSON in §6
    static func ruleList() async -> WKContentRuleList? // cached Task, compile once per process
}
```

One cached `Task<WKContentRuleList?, Never>` replaces the prototype's store class + injectable-compile scaffolding. For testability, allow injecting the compile function via an internal static (or pass a store into the load helper) — pick the smallest seam that lets a unit test force compilation failure.

### 4.4 `WebViewComponentViewModel.swift` (~60 lines)

`urlString`, computed `url: URL?` (validation per §6 — no variable handling of any kind, no `VariableHandlerV2` import), `size`, `visible`, `componentID`, `protocolVersion` (default 1), `locale` from `LocalizationProvider`. `Hashable` over `urlString` **and** `componentID`.

### 4.5 `WebViewComponentView.swift` (~200 lines)

One SwiftUI view + **one** cross-platform representable:

- A ~15-line `PlatformViewRepresentable` shim (`#if os(macOS)` → `NSViewRepresentable`, else `UIViewRepresentable`) so the web view representable is written **once**. Platform differences (iOS scroll/zoom/bounce disabling + zoom user script; macOS website-data wipe on dismantle) are small `#if` blocks inside the single implementation, not duplicated files.
- The view owns the session as `@StateObject`-style storage and applies `.id(<url>-<componentID>)` so a URL change tears down and recreates view + session + web view. **There is no reload/reset path**: session identity == web view identity == URL. (On iOS 15, use `@StateObject` on an `ObservableObject` session or an equivalent owner object; do not reach for iOS-17-only `@Observable`.)
- Sizing is **one path**: session's `resize` → `onContentResize` → `@State var measuredSize: (width: CGFloat?, height: CGFloat?)` → the size modifier (`frame(height: measuredHeight ?? 100)` for `.fit` height, `frame(width: measuredWidth ?? 300)` for `.fit` width; `fill`/`fixed`/`relative` map like other components). **No `intrinsicContentSize` subclass, no size `@Binding` into the representable, no state mutation inside `makeUIView`.**
- WKWebView config: `websiteDataStore = .nonPersistent()`, `allowsInlineMediaPlayback = true`, transparent background, scrolling/bounce/zoom disabled on iOS.
- Navigation policy (new, required — see §6): a `WKNavigationDelegate` restricting main-frame navigation.
- Load path: `Task { guard let rules = await WebViewIsolation.ruleList() else { fail closed }; add rules; load(url) }`.
- `visible == false` or invalid URL ⇒ render nothing. `componentID == nil` ⇒ **render-only mode** (log `paywall_web_view_missing_id`): no session is created and the `rcWebComponents` script handler is **not registered at all** (the content SDK probes for it, finds nothing, falls back to web transport, and retries `connect` harmlessly — expected, not a bug). **Everything security-related applies identically in render-only mode**: content-blocking rules with fail-closed loading, the same-origin navigation policy, non-persistent data store, macOS data wipe. Consequence to accept, not fix: with no session there is never a `resize`, so `fit` axes keep their placeholders permanently.
- **Load failure behavior (fixed for v1): do nothing special.** If the page fails to load (network error, HTTP error, blocked by rules), the frame simply stays blank at its laid-out size. Do NOT implement fallback-component rendering, retry logic, or error UI — Android renders a fallback stack here and iOS knowingly diverges in v1; that reconciliation is explicitly out of scope for this mission.

### 4.6 `PaywallWebViewAPI.swift` — the public surface (see §5)

`PaywallWebViewMessage`, `PaywallWebViewValue` (may stay in `RevenueCatUI/Data/` if you prefer; keep the prototype's file placement conventions), `PaywallWebViewController`, `PaywallWebViewMessageAction`, the environment key, and `View.onPaywallWebViewMessage(_:)`.

### Project registration

New Swift files must be added to `RevenueCat.xcodeproj/project.pbxproj` (RevenueCatUI target; tests to the RevenueCatUITests target). Follow the existing entry pattern (PBXBuildFile + PBXFileReference + group + Sources phase) — study how a recently added RevenueCatUI file is registered and generate fresh 24-hex IDs that don't collide. SPM (`Package.swift`) picks files up by path automatically; the pbxproj does not.

---

## 5. Public API contract (fixed — keep source-compatible with the prototype stack)

```swift
public struct PaywallWebViewMessage {
    public let componentID: String
    public let type: String                                  // plain string, deliberately not an enum
    public let responses: [String: PaywallWebViewValue]?
    public let error: String?
}

public struct PaywallWebViewValue: Hashable /* struct wrapping a private storage enum */ {
    public static func string(_: String) -> Self
    public static func number(_: Double) -> Self
    public static func bool(_: Bool) -> Self
    public static func array(_: [PaywallWebViewValue]) -> Self
    public static func object(_: [String: PaywallWebViewValue]) -> Self
    public static var null: Self { get }
    public var stringValue: String? { get }
    public var numberValue: Double? { get }
    public var boolValue: Bool? { get }
    public var arrayValue: [PaywallWebViewValue]? { get }
    public var objectValue: [String: PaywallWebViewValue]? { get }
    public var isNull: Bool { get }
}

@MainActor public struct PaywallWebViewController {
    public func postVariables(componentID: String, variables: [String: PaywallWebViewValue])
    public func postMessage(componentID: String, type: String, variables: [String: PaywallWebViewValue])
}

/// MainActor closure wrapper used by the environment plumbing (port from the prototype).
public struct PaywallWebViewMessageAction {
    public init(_ action: @escaping @MainActor (PaywallWebViewMessage, PaywallWebViewController) -> Void)
    @MainActor public func callAsFunction(_ message: PaywallWebViewMessage, _ controller: PaywallWebViewController)
}

extension View {
    public func onPaywallWebViewMessage(
        _ action: @escaping @MainActor (PaywallWebViewMessage, PaywallWebViewController) -> Void
    ) -> some View
}
```

**Do not invent this surface — diff it against the prototype.** Before writing these files, extract the exact public declarations from the prototype and match them:

```bash
git fetch origin web-view-bridge-wiring cursor/ios-web-view-bridge-alignment-6044
git show origin/cursor/ios-web-view-bridge-alignment-6044:RevenueCatUI/Data/PaywallWebViewValue.swift
git show origin/cursor/ios-web-view-bridge-alignment-6044:RevenueCatUI/Templates/V2/Components/WebView/PaywallWebViewController.swift
rg -n "public" <each extracted file>
```

Match names, access levels (`public` vs `@_spi`), `@MainActor` annotations, availability, and the SwiftUI environment key name (`paywallWebViewMessageAction`) exactly; internals may differ freely. Copy the doc comments where they exist. Internally, `PaywallWebViewValue`'s storage should be `Codable` so the same type serves the wire and the API.

**Non-finite numbers (decided — do not follow the prototype here):** `.number(_:)` **normalizes** `NaN` and `±infinity` to `.null` at construction, documented in the factory's doc comment. Rationale: JSON cannot represent them (inbound frames containing such tokens are malformed JSON and already dropped); the prototype's outbound path could hit an uncatchable `NSException` via `JSONSerialization` for app-constructed non-finite values, and a throwing `JSONEncoder` alternative would silently kill an entire otherwise-valid message over one bad number. Normalization makes encoding total and removes the `NaN` Hashable-contract hazard (`-0.0` follows plain `Double` equality: `-0.0 == 0.0`). Because this adds public API, the `api/revenuecatui-api-*.swiftinterface` baselines must be regenerated (Definition of done) — find the lane with `rg -i swiftinterface fastlane/Fastfile`.

---

## 6. Security contract (fixed)

**URL validation** (`WebViewComponentViewModel.url`): parse `component.url`; require scheme `https` (case-insensitive) and a non-empty host; anything else (including strings containing `{{`) ⇒ `nil` ⇒ render nothing.

**Origin** = `scheme://host[:port]`, scheme+host lowercased, default ports omitted (443/https, 80/http). Messages (both directions) are valid only while the web view's current URL origin equals the component URL's origin; exception: inbound `connect` and outbound `init`/`reject`/`fit` are allowed while `currentURL` is nil (before the first navigation commits).

**Navigation policy** (improvement over the prototype — required): implement `webView(_:decidePolicyFor:)` to **deny main-frame navigation to any origin other than the component URL's origin** (same-origin different-path navigation is allowed; sub-frame loads are governed by the content rules). This makes cross-origin message races structurally impossible; the per-message origin check remains as defense in depth.

**Content-blocking rules** — exact policy (same-origin subresources and same-origin fetch/XHR allowed; `data:` images/fonts allowed; third-party loads blocked):

```json
[
  {"trigger": {"url-filter": ".*", "resource-type": ["image", "script", "font"], "load-type": ["third-party"]},
   "action": {"type": "block"}},
  {"trigger": {"url-filter": ".*", "resource-type": ["raw"], "load-type": ["third-party"]},
   "action": {"type": "block"}}
]
```

Identifier `rc-webview-v2-isolation`. **Fail closed:** if the rules fail to compile, the page is NOT loaded (log `paywall_web_view_content_rules_failed`). The initial load is deferred until the rule list is attached.

**Also:** main-frame-only messages (`frameInfo.isMainFrame`), non-persistent website data store, macOS wipes all website data on dismantle, JSON built by encoder + U+2028/9 escaping (prototype has hostile-string tests — port them).

**Log strings** (add to `RevenueCatUI/Data/Strings.swift`, port wording from the prototype): `paywall_web_view_missing_id`, `paywall_web_view_message_rejected(reason:)`, `paywall_web_view_post_message_failed`, `paywall_web_view_post_message_skipped`, `paywall_web_view_content_rules_failed`, `paywall_web_view_reserved_locale_stripped`.

---

## 7. Sizing behavior (fixed)

- `fixed` → exact points. `fill` → expand. `relative` → fraction of parent where the shared size-modifier conventions support it.
- `fit` height: **100 pt** placeholder until the first valid `resize`, then the reported height (clamped ≤ 10,000).
- `fit` width: **300 pt** placeholder until the first valid `resize`, then the reported width (clamped ≤ 10,000). (300 matches the web implementation's `FIT_FALLBACK_SIZE_PX`; 100 for height matches the iOS prototype — keep both as named constants with a comment giving these origins.)
- Reported sizes apply only to axes that are `fit` in the schema, and only when the new value differs from the last applied value by ≥ 1 pt (§3). A fit axis is rendered with `frame(width:)`/`frame(height:)` pinned to the placeholder-or-measured value — SwiftUI's exact frames mean there is no CSS-style flex-shrink collapse to guard against, but the value must never be nil for a fit axis or a stack parent may collapse it.
- Width feedback-loop caveat (why the 1 pt threshold and per-axis validation matter): HTML block content has no natural intrinsic width — the content's reported width frequently equals whatever viewport width the host imposed, so an apply → report → apply cycle converges only because same-value applies are no-ops. The `WebViewSessionResizeTests` loop test below is mandatory, not optional.
- A new session (URL change) starts from placeholders again (free, since the session is recreated).

---

## 8. Test plan — the loop target

Tests live in `Tests/RevenueCatUITests/PaywallsV2/`. All message-flow tests construct a `WebViewSession` directly with an injected `evaluateJavaScript` capturer and feed JSON strings to `handle(...)` — no WKWebView needed except where marked *(integration)*. Port assertion content from the prototype's `PaywallWebViewBridgeTests`, `PaywallWebViewMessageParserTests`, `WebViewCapabilitiesTests`, `WebViewComponentTests` where they match; write the rest fresh.

**`WebViewEnvelopeTests`** — decode valid connect/message/request frames; reject: wrong channel, unknown kind, missing component_id, non-string type/id/error, non-object payload; byte-size limit (> 65,536 rejected, large-but-under accepted); depth 16 accepted / 17 rejected; encode → decode round-trip preserves all fields; encoded output contains no raw `\n`, U+2028, or U+2029 for hostile string values (`"annual\" }); alert('xss'); //\n</script>\\ end\u{2028}\u{2029}"` survives a JSON round-trip intact).

**`PaywallWebViewValueTests`** — port the prototype's suite: factory/accessor symmetry, Hashable, Codable round-trip for all six cases, number/bool disambiguation. Non-finite normalization (§5): `.number(.nan)`, `.number(.infinity)`, `.number(-.infinity)` each yield `isNull == true` and `numberValue == nil`; an object containing a normalized value encodes successfully (no throw); `.number(-0.0) == .number(0.0)`.

**`WebViewSessionHandshakeTests`** — `connect` v1 → captured `init` with real component_id and channel open; `connect` v2 → captured `reject` with exact error string `Unsupported protocol_version 2; native host supports 1`, channel closed; app message before connect → dropped, nothing captured; duplicate connect while open → ignored (no second init); `connect` with fill×fit size → `fit` message captured after `init` with payload exactly `{"height": true}` (no `width` key); fit×fixed → exactly `{"width": true}`; fit×fit → both keys `true`; fill×fixed → no `fit` message at all; non-main-frame frame → dropped; string body and dictionary body both accepted.

**`WebViewSessionMessagingTests`** — `rc:step-loaded` reaches handler with correct componentID/type; `rc:step-complete` with `payload.responses` → responses extracted; with flat payload → whole payload as responses; with a reserved key in flat payload → dropped; `rc:error` with `payload.error` → error surfaced; missing error → dropped; unknown type → dropped, handler not called; component_id mismatch → dropped; `rc:request-variables` as message → captured `rc:variables` message whose payload == `{"locale": <BCP-47>}` flat (assert **no** `variables` key), then handler invoked; as request with id `req-1` → captured `response` with same id and type `rc:request-variables`, payload = variables; as request without id → dropped entirely; auto-reply fires with `messageHandler == nil`; locale formats as BCP-47 (`en_US` → `en-US`, `zh_Hans_CN` contains no underscore).

**`WebViewSessionOutboundTests`** — `postVariables` strips reserved `locale` key (and logs) but preserves other keys; `post`/`postVariables` while channel closed → nothing captured; outbound after simulated navigation to a different origin → nothing captured; origin comparison: default port 443 equal, host case-insensitive, different port unequal, different scheme unequal; payloads with all six value types serialize correctly.

**`WebViewSessionResizeTests`** — `resize` as `kind:"message"` updates fit axes and is NOT forwarded to the app handler; `resize` as `kind:"request"` also not forwarded; height applies only when schema height is `.fit`; width applies only when schema width is `.fit` (width report on a fill-width component ignored); a frame reporting both axes updates both when both are fit; non-finite / zero / negative ignored per axis (a frame with invalid width but valid height still applies the height); 99,999 clamps to 10,000 on either axis; a re-report within 1 pt of the last applied value on an axis does not call `onContentResize` for that axis (threshold/feedback-loop guard — mandatory test); a re-report ≥ 1 pt different does.

**`WebViewIsolationTests`** — rules JSON is valid JSON; exactly 2 block rules; image/script/font rule is third-party-only; raw rule is third-party-only; no `data:` blocking rule; identifier == `rc-webview-v2-isolation`; *(integration)* `loadIsolated`-equivalent with an injected failing compile → `webView.url` stays nil (fail closed).

**`WebViewComponentTests`** (schema + view model) — decodes full and minimal JSON with defaults (visible true, protocol_version 1, size fill×fit); unknown keys tolerated; URL validation: accepts https, rejects http/file/custom-scheme/missing-host/`{{`-containing; Hashable includes componentID; exposes decoded protocol_version and locale.

**`WebViewNavigationPolicyTests`** — the policy decision function (factor it as a pure function for testability): same-origin main-frame allow; cross-origin main-frame cancel; sub-frame allow.

**Round-trip *(integration, one test)*** — real `WKWebView` loading HTML via `loadHTMLString(_:baseURL:)`, session registered as the real script handler: JS posts `connect` then `rc:step-loaded` through `window.webkit.messageHandlers.rcWebComponents.postMessage`, assert the app handler received the message. (Port the shape from the prototype's `testWebContentMessageReachesAppHandlerAfterHandshake`.)

**Snapshot** — none required for v1 (the frame is remote content). Ensure existing snapshot suites still pass untouched.

---

## 9. References

- Prototype stack (read for contracts, doc comments, and test content — do not merge or copy wholesale): branches `web-view-schema`, `web-view-content-blocking`, `web-view-render-ios`, `web-view-ios-autosize`, `web-view-render-macos`, `web-view-value`, `web-view-message`, `web-view-bridge-wiring`, and the alignment branch `cursor/ios-web-view-bridge-alignment-6044` (PR #7154 — the most protocol-correct revision; its tests are the best porting source).
- Android reference implementation: `RevenueCat/purchases-android` PR #3655 (`WebViewJavaScriptBridge.kt`, `WebViewEnvelope.kt`) — same native-host contract.
- Protocol source of truth: npm `@revenuecat/workflow-web-components-sdk` README, sections "Wire format (envelope)", "Handshake", "Embedding in native SDKs (iOS/Android)".
- Web host implementation: `RevenueCat/purchases-ui-js` PR #326.

---

## Definition of done

Check every box. If any box cannot be checked, the mission is not complete — fix and re-verify.

**Functional**
- [ ] `web_view` schema decodes (full, minimal, unknown-keys) and is wired into the component enum, view-model factory, cache warming (skip), and unsupported-condition checks.
- [ ] Component renders a WKWebView on iOS and macOS from one shared representable; renders nothing for invalid URL / `visible: false`; `EmptyView` on watchOS; excluded on tvOS.
- [ ] Full handshake + v1 message set + auto-reply + `fit`/`resize` behave exactly per §3 (proven by the tests in §8).
- [ ] Public API per §5 compiles against the same call sites as the prototype (`onPaywallWebViewMessage`, controller methods, message/value types).
- [ ] Every public/`@_spi` declaration matches the prototype in name, access level, `@MainActor`, and availability (proof: extract `rg -n "public|@_spi"` from both trees and diff — differences must be justified in the PR body).
- [ ] Security posture per §6, including the navigation policy and fail-closed rule loading.

**Simplicity (the mission)**
- [ ] Production types in the WebView folder: **at most 8** (envelope+value, session, isolation, view model, view+representable+modifier, public API types, weak-handler shim). No separate parser/dispatcher/bridge-config/bridge-host types.
- [ ] Exactly **one** platform representable implementation (grep proof: no `MacWebViewRepresentable`).
- [ ] Exactly **one** sizing path (grep proof: no `intrinsicContentSize` override, no height `Binding` parameter on the representable).
- [ ] No `[String: Any]` in message parsing (grep proof: `rg "String: Any" RevenueCatUI/Templates/V2/Components/WebView/` returns only the WKScriptMessage body-extraction boundary, or nothing).
- [ ] Production line count for the WebView folder ≤ ~1,200 (`find ... -name '*.swift' | xargs wc -l`).

**Repository health**
- [ ] All new files registered in `RevenueCat.xcodeproj/project.pbxproj` (build proof: the RevenueCatUI scheme compiles).
- [ ] All §8 tests implemented and passing; all pre-existing RevenueCatUI tests still passing.
- [ ] SwiftLint clean (`swiftlint lint --strict` on changed files, honoring the repo config/baseline).
- [ ] `api/revenuecatui-api-*.swiftinterface` baselines regenerated (or, if no Mac is available, the PR body states this explicitly and names the lane).
- [ ] Log strings added to `Strings.swift` with cases covered by the `description` switch.
- [ ] CHANGELOG untouched (feature is unreleased; release notes happen at ship time).
- [ ] **One** branch and **one** draft PR (decided — do not stack; stacking multiplies CI-loop cost for an autonomous agent). Use clean logical commits (schema → envelope/session → isolation → rendering → public API/wiring → tests), apply the `skip-pr-lines-changed-check` label with a one-line justification, and note in the PR body that the branch can be split into a review stack later if the team prefers. The body must map each §4 file to its purpose and each §8 suite to its coverage.

---

## Verification loop

Repeat until green; do not stop after the first failure or the first success — re-run the full loop after every fix.

**If Xcode is available (macOS):**
1. `bundle install` (once), then `bundle exec fastlane test_revenuecatui` — this drives the `RevenueCatUI` scheme with the `CI-RevenueCatUI` test plan. Alternatively `tuist generate` per `Contributing/DEVELOPMENT.md` and run the scheme's tests via `xcodebuild test`.
2. `swiftlint lint --strict` on changed files.
3. Regenerate swiftinterface baselines (lane discoverable via `rg -i swiftinterface fastlane/Fastfile`) and re-run the API-diff check.
4. Fix, commit, repeat until: zero test failures, zero lint violations, zero API-diff failures.

**If Xcode is NOT available (Linux cloud agent):** the loop runs through CI:
1. Commit and push the branch; open/update the draft PR.
2. `gh pr checks <PR> --repo RevenueCat/purchases-ios --watch` until checks settle.
3. For each failure: `gh run view <run-id> --log-failed --repo RevenueCat/purchases-ios` (or the CircleCI link from the check), read the compiler/test output, fix locally, push, and return to step 2.
4. The loop exit condition is: all required checks green except pre-existing failures you can demonstrate exist on `main` (name them in the PR body), plus any manual-approval holds (e.g. `approve-full-tests`), which you note and leave for a human.
5. While waiting on CI, self-review each Definition-of-done box against the diff (`git diff main...HEAD`) — every box must be justifiable from the diff alone.

**Getting stuck protocol:** if the same failure survives three fix attempts, re-read §3/§8 and the Android reference implementation before attempting a fourth; if it survives five, stop and write up the blocker in the PR body with your analysis instead of thrashing.
