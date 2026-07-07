# Paywalls V2 Web View Rebuild Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the Paywalls V2 `web_view` component from `main` with a single session owner, the canonical `rc-web-components` bridge, complete v1 behavior, and a test suite that lets an agent iterate until the implementation is correct.

**Architecture:** Add the schema and renderer as normal Paywalls V2 component integrations, but keep bridge state inside one `@MainActor WebViewSession`. Use Codable envelopes and JSON values instead of ad hoc dictionaries, use the content SDK's `resize` message for fit sizing, and use a single representable file with small platform-specific blocks for iOS/visionOS and macOS.

**Tech Stack:** Swift 5.9+, SwiftUI, WebKit (`WKWebView`, `WKScriptMessageHandler`, `WKNavigationDelegate`, `WKContentRuleList`), XCTest/Nimble, RevenueCatUI public SwiftUI modifiers, fastlane API baseline tooling.

---

## Source of truth

Read this mission doc before starting:

`docs/superpowers/specs/2026-07-07-paywall-web-view-rebuild-mission.md`

The mission doc defines the external behavior. This plan defines the implementation loop.

## Branching and commit rules

- Start from `main`, not from the previous web view draft stack.
- Use a branch named like `cursor/ios-web-view-rebuild-<run-suffix>`.
- Commit at the end of every task.
- Keep each task's commit reviewable on its own.
- Do not add compatibility shims for the old draft stack.
- Do not create public enums.
- Do not add bundle caching, URL substitution, purchase/restore/dismiss messages, or hybrid SDK work.

## File map

Create or modify these files. If the repository moves files before implementation begins, search by the existing type names and keep the same ownership boundaries.

### Core SDK schema

- Modify: `Sources/Paywalls/Components/Common/PaywallComponentBase.swift`
  - add `.webView(WebViewComponent)`
  - add `ComponentType.webView = "web_view"`
  - add encode/decode switch cases
- Create: `Sources/Paywalls/Components/PaywallWebViewComponent.swift`
  - `PaywallComponent.WebViewComponent`
  - `PaywallComponent.PartialWebViewComponent`
- Modify: `Sources/Paywalls/Components/PaywallV2CacheWarming.swift`
  - skip `.webView` in image and video URL collection
- Test: `Tests/UnitTests/Paywalls/Components/PaywallWebViewComponentTests.swift`

### Public RevenueCatUI API

- Create: `RevenueCatUI/Data/PaywallWebViewValue.swift`
- Create: `RevenueCatUI/Data/PaywallWebViewMessage.swift`
- Create: `RevenueCatUI/Data/PaywallWebViewController.swift`
- Create: `RevenueCatUI/Data/PaywallWebViewMessageEnvironment.swift`
- Create: `Tests/APITesters/AllAPITests/RevenueCatUISwiftAPITester/PaywallWebViewAPI.swift`
- Modify: Objective-C API tester only if any new API is exposed to Objective-C; the intended API is SwiftUI-only and does not need Obj-C surface.
- Test: `Tests/RevenueCatUITests/PaywallsV2/PaywallWebViewValueTests.swift`

### Bridge/session internals

- Create directory: `RevenueCatUI/Templates/V2/Components/WebView/`
- Create: `RevenueCatUI/Templates/V2/Components/WebView/WebViewEnvelope.swift`
- Create: `RevenueCatUI/Templates/V2/Components/WebView/WebViewOrigin.swift`
- Create: `RevenueCatUI/Templates/V2/Components/WebView/WebViewSession.swift`
- Create: `RevenueCatUI/Templates/V2/Components/WebView/WebViewIsolation.swift`
- Test: `Tests/RevenueCatUITests/PaywallsV2/WebViewEnvelopeTests.swift`
- Test: `Tests/RevenueCatUITests/PaywallsV2/WebViewOriginTests.swift`
- Test: `Tests/RevenueCatUITests/PaywallsV2/WebViewSessionTests.swift`
- Test: `Tests/RevenueCatUITests/PaywallsV2/WebViewIsolationTests.swift`

### Rendering

- Create: `RevenueCatUI/Templates/V2/Components/WebView/WebViewComponentViewModel.swift`
- Create: `RevenueCatUI/Templates/V2/Components/WebView/WebViewComponentView.swift`
- Create: `RevenueCatUI/Templates/V2/Components/WebView/WebViewRepresentable.swift`
- Modify: `RevenueCatUI/Templates/V2/ViewModelHelpers/PaywallComponentViewModel.swift`
- Modify: `RevenueCatUI/Templates/V2/ViewModelHelpers/ViewModelFactory.swift`
- Modify: `RevenueCatUI/Templates/V2/Components/ComponentsView.swift`
- Test: `Tests/RevenueCatUITests/PaywallsV2/WebViewComponentViewModelTests.swift`
- Test: `Tests/RevenueCatUITests/PaywallsV2/WebViewComponentViewTests.swift`

### API baselines

- Modify generated files only if public RevenueCatUI API changes:
  - `api/revenuecatui-api-ios.swiftinterface`
  - `api/revenuecatui-api-ios-simulator.swiftinterface`
  - `api/revenuecatui-api-macos.swiftinterface`
  - `api/revenuecatui-api-watchos.swiftinterface`
  - `api/revenuecatui-api-watchos-simulator.swiftinterface`
  - `api/revenuecatui-api-tvos.swiftinterface`
  - `api/revenuecatui-api-tvos-simulator.swiftinterface`
  - `api/revenuecatui-api-visionos.swiftinterface`
  - `api/revenuecatui-api-visionos-simulator.swiftinterface`

## Protocol constants

Use these exact strings:

```swift
enum WebViewProtocol {
    static let channel = "rc-web-components"
    static let scriptMessageHandler = "rcWebComponents"
    static let receiveFunction = "__rcWebComponentsReceive"
    static let supportedProtocolVersion = 1
    static let maxInboundBytes = 64 * 1024
    static let maxPayloadDepth = 16
}
```

Known app message types:

```swift
enum WebViewMessageType {
    static let fit = "fit"
    static let resize = "resize"
    static let stepLoaded = "rc:step-loaded"
    static let stepComplete = "rc:step-complete"
    static let requestVariables = "rc:request-variables"
    static let variables = "rc:variables"
    static let error = "rc:error"
}
```

These may be `internal enum`s because they are not public API.

## Task 1: Schema and cache warming

**Files:**

- Modify: `Sources/Paywalls/Components/Common/PaywallComponentBase.swift`
- Create: `Sources/Paywalls/Components/PaywallWebViewComponent.swift`
- Modify: `Sources/Paywalls/Components/PaywallV2CacheWarming.swift`
- Test: `Tests/UnitTests/Paywalls/Components/PaywallWebViewComponentTests.swift`

- [ ] **Step 1: Write schema decode tests**

Add tests with these names:

```swift
final class PaywallWebViewComponentTests: TestCase {

    func testDecodesWebViewComponent() throws
    func testEncodesWebViewComponentWithSnakeCaseType() throws
    func testDecodesGenericFallbackComponent() throws
    func testRejectsMissingProtocolVersion() throws
    func testDecodesUnsupportedProtocolVersionForRendererDecision() throws
    func testCacheWarmingSkipsWebViewURL() throws
}
```

Use JSON shaped like:

```json
{
  "type": "web_view",
  "id": "component-id",
  "name": "Survey",
  "visible": true,
  "url": "https://abc.components.revenuecat-static.com/index.html",
  "protocol_version": 1,
  "size": {
    "width": { "type": "fill" },
    "height": { "type": "fit" }
  },
  "fallback": {
    "type": "stack",
    "components": [],
    "size": {
      "width": { "type": "fill" },
      "height": { "type": "fit" }
    }
  }
}
```

Expected first run:

```bash
bundle exec fastlane ios test_revenuecatui
```

Expected: tests do not compile because `PaywallComponent.WebViewComponent` does not exist.

- [ ] **Step 2: Implement the component type**

Add `PaywallComponent.WebViewComponent` with these properties:

```swift
@_spi(Internal) public extension PaywallComponent {

    final class WebViewComponent: PaywallComponentBase {
        let type: ComponentType
        public let id: String?
        public let name: String?
        public let visible: Bool?
        public let url: String
        public let protocolVersion: Int
        public let size: Size
        public let backgroundColor: ColorScheme?
        public let background: Background?
        public let padding: Padding
        public let margin: Padding
        public let shape: Shape?
        public let border: Border?
        public let shadow: Shadow?
        public let fallback: PaywallComponent?
        public let overrides: ComponentOverrides<PartialWebViewComponent>?
    }
}
```

Use coding keys:

```swift
private enum CodingKeys: String, CodingKey {
    case id
    case name
    case visible
    case url
    case protocolVersion = "protocol_version"
    case size
    case backgroundColor = "background_color"
    case background
    case padding
    case margin
    case shape
    case border
    case shadow
    case fallback
    case overrides
}
```

Define `PartialWebViewComponent` with optional versions of all overrideable rendering properties:

```swift
public final class PartialWebViewComponent: PaywallPartialComponent {
    public let visible: Bool?
    public let size: Size?
    public let backgroundColor: ColorScheme?
    public let background: Background?
    public let padding: Padding?
    public let margin: Padding?
    public let shape: Shape?
    public let border: Border?
    public let shadow: Shadow?
}
```

Do not include `url` or `protocolVersion` in partial overrides.

- [ ] **Step 3: Wire `PaywallComponent` enum**

In `PaywallComponent`:

```swift
case webView(WebViewComponent)
```

In `ComponentType`:

```swift
case webView = "web_view"
```

Add encode and decode switch cases matching existing component patterns.

Unsupported `protocol_version` values must decode into `WebViewComponent.protocolVersion`. The renderer decides whether to render fallback for unsupported versions. Schema decoding should throw for a missing required `protocol_version`, but not for an unsupported numeric value because throwing would discard the decoded fallback.

- [ ] **Step 4: Skip cache warming**

In `PaywallV2CacheWarming`, add `.webView` to the cases that return no image or video URLs. The web view loads the remote HTTPS URL directly and should not be prefetched into the SDK file cache.

- [ ] **Step 5: Run focused tests and commit**

Run:

```bash
bundle exec fastlane ios test_revenuecatui
```

Then run:

```bash
swift build
```

Expected: no compile errors from schema additions.

Commit:

```bash
git add Sources/Paywalls/Components/Common/PaywallComponentBase.swift Sources/Paywalls/Components/PaywallWebViewComponent.swift Sources/Paywalls/Components/PaywallV2CacheWarming.swift Tests/UnitTests/Paywalls/Components/PaywallWebViewComponentTests.swift
git commit -m "Add Paywalls V2 web view schema"
```

## Task 2: Public RevenueCatUI API

**Files:**

- Create: `RevenueCatUI/Data/PaywallWebViewValue.swift`
- Create: `RevenueCatUI/Data/PaywallWebViewMessage.swift`
- Create: `RevenueCatUI/Data/PaywallWebViewController.swift`
- Create: `RevenueCatUI/Data/PaywallWebViewMessageEnvironment.swift`
- Create: `Tests/APITesters/AllAPITests/RevenueCatUISwiftAPITester/PaywallWebViewAPI.swift`
- Test: `Tests/RevenueCatUITests/PaywallsV2/PaywallWebViewValueTests.swift`

- [ ] **Step 1: Write value tests**

Add tests:

```swift
final class PaywallWebViewValueTests: TestCase {
    func testStringValueRoundTripsThroughJSON() throws
    func testNumberValueRoundTripsThroughJSON() throws
    func testBoolValueRoundTripsThroughJSON() throws
    func testNullValueRoundTripsThroughJSON() throws
    func testArrayValueRoundTripsThroughJSON() throws
    func testObjectValueRoundTripsThroughJSON() throws
    func testRejectsPayloadDeeperThanSixteenLevels() throws
    func testBooleanDoesNotDecodeAsNumber() throws
}
```

- [ ] **Step 2: Add `PaywallWebViewValue`**

Use a public struct with private storage:

```swift
public struct PaywallWebViewValue: Sendable, Hashable, Codable {
    public init(_ value: String)
    public init(_ value: Double)
    public init(_ value: Bool)
    public static var null: PaywallWebViewValue { get }
    public static func array(_ values: [PaywallWebViewValue]) -> PaywallWebViewValue
    public static func object(_ values: [String: PaywallWebViewValue]) -> PaywallWebViewValue
}
```

Keep the storage enum private. This follows the repository rule against new consumer-facing public enums.

- [ ] **Step 3: Add `PaywallWebViewMessage`**

Use a public struct:

```swift
public struct PaywallWebViewMessage: Sendable, Hashable {
    public let componentID: String
    public let type: String
    public let payload: [String: PaywallWebViewValue]
    public let responses: [String: PaywallWebViewValue]
    public let error: String?
}
```

Add static type constants:

```swift
public static let stepLoadedType = "rc:step-loaded"
public static let stepCompleteType = "rc:step-complete"
public static let requestVariablesType = "rc:request-variables"
public static let errorType = "rc:error"
```

Do not make a public enum of message cases.

- [ ] **Step 4: Add `PaywallWebViewController`**

Public surface:

```swift
@MainActor
public final class PaywallWebViewController {
    public func postVariables(_ variables: [String: PaywallWebViewValue])
    public func postMessage(type: String, payload: [String: PaywallWebViewValue])
}
```

The implementation may hold an internal weak session reference. If `variables` includes `locale`, strip it and log because `locale` is SDK-managed.

- [ ] **Step 5: Add SwiftUI environment modifier**

Define:

```swift
public typealias PaywallWebViewMessageAction = @MainActor (
    PaywallWebViewMessage,
    PaywallWebViewController
) -> Void

public extension View {
    func onPaywallWebViewMessage(_ handler: PaywallWebViewMessageAction?) -> some View
}
```

Store it in an `EnvironmentKey`.

- [ ] **Step 6: Update API tester**

Add Swift API tester usage:

```swift
_ = PaywallWebViewValue("hello")
_ = PaywallWebViewValue(1.5)
_ = PaywallWebViewValue(true)
_ = PaywallWebViewValue.null
_ = PaywallWebViewValue.array([.init("a")])
_ = PaywallWebViewValue.object(["locale": .init("en-US")])
_ = EmptyView().onPaywallWebViewMessage { message, controller in
    controller.postVariables(["answer": .init("yes")])
    controller.postMessage(type: message.type, payload: message.payload)
}
```

- [ ] **Step 7: Run tests and commit**

Run:

```bash
bundle exec fastlane ios test_revenuecatui
```

Do not run `bundle exec fastlane ios run_api_tests` as a required gate in this task. The new public API will require RevenueCatUI swiftinterface baseline handling, which is intentionally centralized in Task 10 after all public surface is stable.

Commit:

```bash
git add RevenueCatUI/Data/PaywallWebViewValue.swift RevenueCatUI/Data/PaywallWebViewMessage.swift RevenueCatUI/Data/PaywallWebViewController.swift RevenueCatUI/Data/PaywallWebViewMessageEnvironment.swift Tests/APITesters/AllAPITests/RevenueCatUISwiftAPITester/PaywallWebViewAPI.swift Tests/RevenueCatUITests/PaywallsV2/PaywallWebViewValueTests.swift
git commit -m "Add web view message API"
```

## Task 3: Codable envelope and origin model

**Files:**

- Create: `RevenueCatUI/Templates/V2/Components/WebView/WebViewEnvelope.swift`
- Create: `RevenueCatUI/Templates/V2/Components/WebView/WebViewOrigin.swift`
- Test: `Tests/RevenueCatUITests/PaywallsV2/WebViewEnvelopeTests.swift`
- Test: `Tests/RevenueCatUITests/PaywallsV2/WebViewOriginTests.swift`

- [ ] **Step 1: Write envelope tests**

Add tests:

```swift
final class WebViewEnvelopeTests: TestCase {
    func testDecodesConnectEnvelopeFromJSONString() throws
    func testEncodesInitEnvelopeWithSnakeCaseKeys() throws
    func testDropsWrongChannel() throws
    func testRejectsPayloadOverSixtyFourKiB() throws
    func testRejectsPayloadDepthGreaterThanSixteen() throws
    func testEscapesLineSeparatorsAndClosingScriptTagForJavaScriptDelivery() throws
}
```

Add tests:

```swift
final class WebViewOriginTests: TestCase {
    func testOriginsMatchWithDefaultHTTPSPort() throws
    func testOriginsMatchCaseInsensitiveHosts() throws
    func testOriginsDifferForDifferentPorts() throws
    func testOriginsDifferForDifferentSchemes() throws
    func testInvalidURLHasNoOrigin() throws
}
```

- [ ] **Step 2: Implement `WebViewEnvelope`**

Use Codable and Equatable. Required fields for all inbound envelopes:

- `channel`
- `protocol_version`
- `kind`
- `component_id`

Optional fields:

- `type`
- `id`
- `payload`
- `error`

Add helpers:

```swift
static func decodeInbound(_ raw: String) throws -> WebViewEnvelope
func encodedForJavaScriptReceive() throws -> String
```

`encodedForJavaScriptReceive()` returns only the JSON argument string. `WebViewSession` will wrap it in the `typeof` guard.

- [ ] **Step 3: Implement `WebViewOrigin`**

Use:

```swift
struct WebViewOrigin: Equatable, Hashable {
    let scheme: String
    let host: String
    let port: Int

    init?(url: URL)
    func matches(_ url: URL?) -> Bool
}
```

Normalize:

- scheme lowercased
- host lowercased
- HTTPS default port 443
- HTTP default port 80, used only for comparison tests because web view URLs must be HTTPS

- [ ] **Step 4: Run tests and commit**

Run:

```bash
bundle exec fastlane ios test_revenuecatui
```

Commit:

```bash
git add RevenueCatUI/Templates/V2/Components/WebView/WebViewEnvelope.swift RevenueCatUI/Templates/V2/Components/WebView/WebViewOrigin.swift Tests/RevenueCatUITests/PaywallsV2/WebViewEnvelopeTests.swift Tests/RevenueCatUITests/PaywallsV2/WebViewOriginTests.swift
git commit -m "Add web view envelope primitives"
```

## Task 4: Web view session handshake and outbound delivery

**Files:**

- Create: `RevenueCatUI/Templates/V2/Components/WebView/WebViewSession.swift`
- Test: `Tests/RevenueCatUITests/PaywallsV2/WebViewSessionTests.swift`

- [ ] **Step 1: Write session handshake tests**

Add tests:

```swift
final class WebViewSessionTests: TestCase {
    func testConnectSendsInitAndOpensChannel() throws
    func testVersionMismatchSendsRejectAndKeepsChannelClosed() throws
    func testAppMessageBeforeConnectIsDropped() throws
    func testOutboundDeliveryUsesReceiveGlobalWithTypeofGuard() throws
    func testOutboundDeliveryDropsWhenOriginDoesNotMatch() throws
    func testDuplicateConnectWhileOpenDoesNotDeliverDuplicateFit() throws
}
```

Tests should instantiate `WebViewSession` with:

- component id
- component URL
- protocol version
- size
- `currentURL` closure
- `evaluateJavaScript` capture closure
- locale provider closure

No test in this task should need a live `WKWebView`.

- [ ] **Step 2: Implement session skeleton**

Session owns:

```swift
@MainActor
final class WebViewSession: NSObject, ObservableObject, WKScriptMessageHandler, WKNavigationDelegate {
    @Published private(set) var measuredSize: CGSize?
    @Published private(set) var loadFailed = false

    private(set) var channelOpen = false
    private weak var webView: WKWebView?
    private let currentURL: () -> URL?
    private let localeProvider: () -> Locale
    private let evaluateJavaScript: (String) -> Void
}
```

Use an initializer that tests can call without a `WKWebView`. Production can call `start(in:)` later.

- [ ] **Step 3: Implement `connect`**

When inbound envelope is:

```json
{ "kind": "connect", "protocol_version": 1 }
```

send:

```json
{
  "channel": "rc-web-components",
  "protocol_version": 1,
  "kind": "init",
  "component_id": "<real component id>"
}
```

Then set `channelOpen = true`.

When version mismatches, send:

```json
{
  "channel": "rc-web-components",
  "protocol_version": 1,
  "kind": "reject",
  "component_id": "",
  "error": "Unsupported protocol_version N; native host supports 1"
}
```

Do not open the channel.

- [ ] **Step 4: Implement guarded JavaScript delivery**

The evaluated script must be shaped like:

```javascript
if (typeof window.__rcWebComponentsReceive === 'function') {
  window.__rcWebComponentsReceive({"channel":"rc-web-components", ...})
}
```

Build JSON with `JSONEncoder` or `JSONSerialization`. Never interpolate payload values into JavaScript manually.

- [ ] **Step 5: Send `fit` after `init`**

If `size.width == .fit` or `size.height == .fit`, send a second envelope after `init`:

```json
{
  "kind": "message",
  "type": "fit",
  "payload": { "height": true }
}
```

Include only axes that are `fit`.

- [ ] **Step 6: Run tests and commit**

Run:

```bash
bundle exec fastlane ios test_revenuecatui
```

Commit:

```bash
git add RevenueCatUI/Templates/V2/Components/WebView/WebViewSession.swift Tests/RevenueCatUITests/PaywallsV2/WebViewSessionTests.swift
git commit -m "Add web view session handshake"
```

## Task 5: Variables, app messages, and resize

**Files:**

- Modify: `RevenueCatUI/Templates/V2/Components/WebView/WebViewSession.swift`
- Modify: `RevenueCatUI/Data/PaywallWebViewController.swift`
- Modify: `Tests/RevenueCatUITests/PaywallsV2/WebViewSessionTests.swift`

- [ ] **Step 1: Add message routing tests**

Add tests:

```swift
func testRequestVariablesRequestSendsResponseWithSameIDAndType() throws
func testRequestVariablesMessageSendsVariablesMessage() throws
func testVariablesPayloadIsFlatMap() throws
func testRequestVariablesWorksWithoutAppHandler() throws
func testStepLoadedDeliversAppMessage() throws
func testStepCompleteReadsResponsesObject() throws
func testStepCompleteUsesPayloadWhenResponsesObjectIsAbsent() throws
func testErrorMessageReadsPayloadError() throws
func testUnknownMessageTypeIsDropped() throws
func testResizeUpdatesMeasuredSizeAndDoesNotReachAppHandler() throws
func testResizeRequestDoesNotReachAppHandler() throws
func testPostVariablesStripsReservedLocaleKey() throws
func testSDKVariablesUseBCP47LocaleIdentifier() throws
```

- [ ] **Step 2: Implement SDK variables**

SDK-managed variables in v1:

```swift
["locale": PaywallWebViewValue(locale.bcp47Identifier)]
```

Use a BCP-47 identifier with hyphens, for example `en-US`, not the underscore form commonly returned by `Locale.identifier`. If the repository has an existing Locale extension for preferred BCP-47 identifiers, use it. Otherwise, normalize the injected locale identifier by replacing underscores with hyphens and add a test that `Locale(identifier: "en_US")` produces `en-US`.

- [ ] **Step 3: Implement `rc:request-variables`**

If inbound kind is `request`, require `id` and reply:

```json
{
  "kind": "response",
  "id": "<same id>",
  "type": "rc:request-variables",
  "payload": { "locale": "en-US" }
}
```

If inbound kind is `message`, reply:

```json
{
  "kind": "message",
  "type": "rc:variables",
  "payload": { "locale": "en-US" }
}
```

Then deliver a `PaywallWebViewMessage` to the app handler when a handler exists.

- [ ] **Step 4: Implement app message extraction**

Create internal conversion from `WebViewEnvelope` to `PaywallWebViewMessage`.

Rules:

- `rc:step-loaded`: empty payload and responses
- `rc:step-complete`: responses from `payload.responses` when it is an object; otherwise use payload object minus reserved keys
- `rc:error`: error from `payload.error` first, then envelope `error`
- unknown type: debug log and drop

- [ ] **Step 5: Implement resize**

If `type == "resize"`, do not call the app handler. Read:

```json
{ "width": 320, "height": 480 }
```

For each `fit` axis:

- accept finite values greater than zero
- clamp to `10_000`
- store in `measuredSize`

Ignore non-fit axes.

- [ ] **Step 6: Implement controller outbound methods**

`PaywallWebViewController.postVariables` sends:

```json
{
  "kind": "message",
  "type": "rc:variables",
  "payload": { ... }
}
```

`postMessage(type:payload:)` sends:

```json
{
  "kind": "message",
  "type": "<type>",
  "payload": { ... }
}
```

Both require an open channel and matching origin. Both drop silently if the session has gone away.

- [ ] **Step 7: Run tests and commit**

Run:

```bash
bundle exec fastlane ios test_revenuecatui
```

Commit:

```bash
git add RevenueCatUI/Templates/V2/Components/WebView/WebViewSession.swift RevenueCatUI/Data/PaywallWebViewController.swift Tests/RevenueCatUITests/PaywallsV2/WebViewSessionTests.swift
git commit -m "Handle web view protocol messages"
```

## Task 6: Content isolation

**Files:**

- Create: `RevenueCatUI/Templates/V2/Components/WebView/WebViewIsolation.swift`
- Test: `Tests/RevenueCatUITests/PaywallsV2/WebViewIsolationTests.swift`

- [ ] **Step 1: Write isolation tests**

Add tests:

```swift
final class WebViewIsolationTests: TestCase {
    func testRuleListBlocksThirdPartyImageScriptFontAndRawLoads() throws
    func testRuleListAllowsDataImagesAndFonts() throws
    func testRuleListIdentifierIncludesPolicyVersion() throws
    func testCompilationFailureMarksSessionLoadFailedBeforeNavigationStarts() async throws
}
```

- [ ] **Step 2: Implement rules JSON**

Policy:

- block third-party image/script/font
- block third-party raw loads
- allow same-origin fetch/XHR
- allow `data:` image and font resources

Represent as an internal JSON string constant so tests can decode and assert the exact actions/triggers.

- [ ] **Step 3: Compile once**

Use a cached task or actor-isolated cache:

```swift
enum WebViewIsolation {
    static let identifier = "rc-webview-v2-isolation"
    static func ruleList() async -> WKContentRuleList?
}
```

Tests may inject a compiler closure internally. Keep the production API simple.

- [ ] **Step 4: Run tests and commit**

Run:

```bash
bundle exec fastlane ios test_revenuecatui
```

Commit:

```bash
git add RevenueCatUI/Templates/V2/Components/WebView/WebViewIsolation.swift Tests/RevenueCatUITests/PaywallsV2/WebViewIsolationTests.swift
git commit -m "Add web view content isolation"
```

## Task 7: View model and fallback preparation

**Files:**

- Create: `RevenueCatUI/Templates/V2/Components/WebView/WebViewComponentViewModel.swift`
- Modify: `RevenueCatUI/Templates/V2/ViewModelHelpers/PaywallComponentViewModel.swift`
- Modify: `RevenueCatUI/Templates/V2/ViewModelHelpers/ViewModelFactory.swift`
- Test: `Tests/RevenueCatUITests/PaywallsV2/WebViewComponentViewModelTests.swift`

- [ ] **Step 1: Write view model tests**

Add tests:

```swift
final class WebViewComponentViewModelTests: TestCase {
    func testValidHTTPSURLIsAccepted() throws
    func testHTTPURLIsRejected() throws
    func testFileURLIsRejected() throws
    func testCustomSchemeURLIsRejected() throws
    func testMissingHostIsRejected() throws
    func testURLContainingTemplateSyntaxIsRejected() throws
    func testUnsupportedProtocolVersionIsMarkedUnsupported() throws
    func testUnsupportedProtocolVersionPreservesFallbackViewModel() throws
    func testHashableIncludesComponentIDAndURL() throws
    func testFallbackViewModelIsBuiltWhenFallbackExists() throws
}
```

- [ ] **Step 2: Implement style model**

Use a style struct:

```swift
struct WebViewComponentStyle {
    let visible: Bool
    let url: URL?
    let protocolVersion: Int
    let isProtocolSupported: Bool
    let size: PaywallComponent.Size
    let backgroundColor: DisplayableColorScheme?
    let background: PaywallComponent.Background?
    let padding: EdgeInsets
    let margin: EdgeInsets
    let shape: ShapeModifier.Shape?
    let border: ShapeModifier.BorderInfo?
    let shadow: ShadowModifier.ShadowInfo?
}
```

- [ ] **Step 3: Implement URL validation**

Validation:

- parse from `component.url`
- reject strings containing `{{` or `}}`
- require `https`
- require non-empty host

Do not read `customPaywallVariables` for URL resolution.

- [ ] **Step 4: Build fallback view model**

If `component.fallback` exists, use `ViewModelFactory.toViewModel` to build a fallback `PaywallComponentViewModel`. Avoid recursion loops by letting normal component decoding fail if fallback recursively points to itself through data.

- [ ] **Step 5: Wire enum and factory**

Add:

```swift
case webView(WebViewComponentViewModel)
```

In `ViewModelFactory.toViewModel`, return `.webView(...)`.

- [ ] **Step 6: Run tests and commit**

Run:

```bash
bundle exec fastlane ios test_revenuecatui
```

Commit:

```bash
git add RevenueCatUI/Templates/V2/Components/WebView/WebViewComponentViewModel.swift RevenueCatUI/Templates/V2/ViewModelHelpers/PaywallComponentViewModel.swift RevenueCatUI/Templates/V2/ViewModelHelpers/ViewModelFactory.swift Tests/RevenueCatUITests/PaywallsV2/WebViewComponentViewModelTests.swift
git commit -m "Add web view view model"
```

## Task 8: SwiftUI view and representable

**Files:**

- Create: `RevenueCatUI/Templates/V2/Components/WebView/WebViewComponentView.swift`
- Create: `RevenueCatUI/Templates/V2/Components/WebView/WebViewRepresentable.swift`
- Modify: `RevenueCatUI/Templates/V2/Components/ComponentsView.swift`
- Test: `Tests/RevenueCatUITests/PaywallsV2/WebViewComponentViewTests.swift`

- [ ] **Step 1: Write rendering tests**

Add tests:

```swift
final class WebViewComponentViewTests: TestCase {
    func testInvalidURLRendersFallback() throws
    func testUnsupportedProtocolVersionRendersFallback() throws
    func testInvisibleComponentRendersNothingEvenWhenFallbackExists() throws
    func testUnsupportedWebKitPlatformRendersFallbackWhenAvailable() throws
    func testNoFallbackRendersEmptyForInvalidURL() throws
    func testFitHeightUsesMeasuredResizeHeight() throws
    func testFixedHeightIgnoresMeasuredResizeHeight() throws
}
```

If view inspection is not already available, put the sizing logic in a small internal pure function and test that function directly:

```swift
static func resolvedFrameSize(schemaSize: PaywallComponent.Size, measuredSize: CGSize?) -> CGSize?
```

- [ ] **Step 2: Implement SwiftUI view**

View behavior:

- read `onPaywallWebViewMessage` from environment
- create `@StateObject` session for valid URL and supported protocol
- pass app handler into session on body updates
- render fallback if style invalid or `session.loadFailed`
- render web view otherwise
- use `.id("\(componentID)|\(url.absoluteString)")`
- apply background, padding, shape, border, shadow, margin consistently with nearby component views

Sizing:

- if width is `.fit`, use `session.measuredSize?.width`
- if height is `.fit`, use `session.measuredSize?.height`
- before first fit-height resize, use a 100 point initial height
- fixed and fill axes follow existing `SizeModifier` semantics

- [ ] **Step 3: Implement representable**

Keep one file. Gate every WebKit import and representable conformance so watchOS and tvOS builds do not reference unavailable WebKit APIs. Use conditional conformances:

```swift
#if canImport(WebKit) && os(macOS)
extension WebViewRepresentable: NSViewRepresentable { ... }
#elseif canImport(WebKit) && !os(tvOS) && !os(watchOS)
extension WebViewRepresentable: UIViewRepresentable { ... }
#endif
```

On unsupported platforms, `WebViewComponentView` must compile without importing WebKit and must render fallback or `EmptyView` based on the view model state. The schema and public value/message API may still compile on those platforms.

Shared setup:

- `WKWebViewConfiguration.websiteDataStore = .nonPersistent()`
- add `WeakScriptMessageHandler` if the repository already has one; otherwise create a private helper in this file
- disable scrolling inside the web view
- transparent background where supported
- call `session.start(in:)`
- remove script message handler in dismantle

- [ ] **Step 4: Wire `ComponentsView`**

Add:

```swift
case .webView(let viewModel):
    WebViewComponentView(viewModel: viewModel, onDismiss: onDismiss)
```

The `onDismiss` parameter is present only if fallback rendering needs nested component views that require it.

- [ ] **Step 5: Run tests and commit**

Run:

```bash
bundle exec fastlane ios test_revenuecatui
```

Commit:

```bash
git add RevenueCatUI/Templates/V2/Components/WebView/WebViewComponentView.swift RevenueCatUI/Templates/V2/Components/WebView/WebViewRepresentable.swift RevenueCatUI/Templates/V2/Components/ComponentsView.swift Tests/RevenueCatUITests/PaywallsV2/WebViewComponentViewTests.swift
git commit -m "Render Paywalls V2 web view component"
```

## Task 9: Navigation policy and load failure

**Files:**

- Modify: `RevenueCatUI/Templates/V2/Components/WebView/WebViewSession.swift`
- Modify: `RevenueCatUI/Templates/V2/Components/WebView/WebViewRepresentable.swift`
- Modify: `Tests/RevenueCatUITests/PaywallsV2/WebViewSessionTests.swift`

- [ ] **Step 1: Add navigation tests**

Add tests:

```swift
func testAllowsMainFrameNavigationToComponentOrigin() throws
func testCancelsMainFrameNavigationToDifferentOrigin() throws
func testAllowsSubframeNavigationDecisionToDeferToWebKit() throws
func testHTTPStatusFourHundredMarksLoadFailed() throws
func testCancelledNavigationDoesNotMarkLoadFailed() throws
func testRuleListFailureMarksLoadFailedAndDoesNotLoadRequest() async throws
```

- [ ] **Step 2: Implement navigation delegate**

Policy:

- main-frame navigation to component origin: allow
- main-frame navigation to any other origin: cancel
- subframe navigation: allow unless WebKit/content rules block it

Load failure:

- HTTP status `>= 400`: `loadFailed = true`
- `NSURLErrorCancelled`: do not mark failed
- non-benign main-frame errors: `loadFailed = true`

- [ ] **Step 3: Fail closed before load**

`start(in:)` must:

1. await isolation rule list
2. if unavailable, set `loadFailed = true` and return
3. add rule list
4. register handler
5. set navigation delegate
6. load the request

No page load should happen before isolation is installed.

- [ ] **Step 4: Run tests and commit**

Run:

```bash
bundle exec fastlane ios test_revenuecatui
```

Commit:

```bash
git add RevenueCatUI/Templates/V2/Components/WebView/WebViewSession.swift RevenueCatUI/Templates/V2/Components/WebView/WebViewRepresentable.swift Tests/RevenueCatUITests/PaywallsV2/WebViewSessionTests.swift
git commit -m "Enforce web view navigation policy"
```

## Task 10: Full integration and API baselines

**Files:**

- Modify as needed:
  - `api/revenuecatui-api-*.swiftinterface`
  - `RevenueCatUI.podspec` only if source file inclusion requires it
  - `Package.swift` only if target file lists are explicit
  - Tuist project helpers only if files are explicitly enumerated

- [ ] **Step 1: Search for file list requirements**

Run:

```bash
rg -n "PaywallWebView|PaywallComponentViewModel|RevenueCatUI/Data|Templates/V2/Components" Package.swift Tuist RevenueCatUI.podspec RevenueCat.podspec Projects
```

If the build uses globbed sources, no project file update is needed. If a file list is explicit, add every new Swift file.

- [ ] **Step 2: Verify legacy names are absent**

Run:

```bash
rg -n "rcWebViewMessage|rcWebViewHeight|RevenueCatWebView|__revenueCatReceiveMessage|__rcMeasureHeight|__rcReportHeight" -g "*.swift"
```

Expected: no results.

Run:

```bash
rg -n "VariableHandlerV2|customPaywallVariables" RevenueCatUI/Templates/V2/Components/WebView -g "*.swift"
```

Expected: no results.

- [ ] **Step 3: Run main verification commands**

Run:

```bash
swift build
swiftlint
bundle exec fastlane ios test_revenuecatui
bundle exec fastlane ios run_api_tests
```

If running on Linux cannot execute Xcode-dependent lanes, push and use CI for those lanes. Do not mark them passing in the PR body until CI confirms them.

- [ ] **Step 4: Regenerate API baselines if needed**

If `run_api_tests` or CI reports RevenueCatUI API diffs, regenerate:

```bash
bundle exec fastlane ios update_swiftinterface_baselines scheme:RevenueCatUI
```

Add only the generated RevenueCatUI interface files relevant to the diff.

- [ ] **Step 5: Commit integration cleanup**

Commit:

```bash
git add Package.swift Tuist RevenueCatUI.podspec api/revenuecatui-api-*.swiftinterface
git commit -m "Update web view integration metadata"
```

If none of those files changed, skip this commit and record that fact in the PR body.

## Task 11: End-to-end verification PR checklist

**Files:**

- Modify: PR body only

- [ ] **Step 1: Run final searches**

Run:

```bash
rg -n "web_view" Sources RevenueCatUI Tests -g "*.swift"
rg -n "rcWebComponents|__rcWebComponentsReceive|rc-web-components" RevenueCatUI Tests -g "*.swift"
rg -n "rcWebViewMessage|rcWebViewHeight|RevenueCatWebView|__revenueCatReceiveMessage" RevenueCatUI Tests Sources -g "*.swift"
```

Expected:

- first search shows schema, rendering, and tests
- second search shows canonical bridge names
- third search shows no results

- [ ] **Step 2: Run final verification**

Run:

```bash
git diff --check
swift build
swiftlint
bundle exec fastlane ios test_revenuecatui
bundle exec fastlane ios run_api_tests
```

If any command cannot run in the current environment, include the exact command, failure reason, and required CI lane in the PR body.

- [ ] **Step 3: PR body content**

Use the repo template:

```markdown
### Checklist
- [x] If applicable, unit tests
- [ ] If applicable, create follow-up issues for `purchases-android` and hybrids

### Motivation
Adds the Paywalls V2 web view component with a simpler single-session architecture that matches the canonical workflow web components bridge contract.

### Description
This builds the component from `main` rather than porting the previous draft stack. The web view loads static HTTPS RevenueCat-hosted bundles, uses `rcWebComponents` / `__rcWebComponentsReceive` for the handshake and app messages, sizes `fit` axes through the SDK `resize` message, fails closed when isolation cannot be installed, and renders generic fallback on determined load failure.

Testing:
- `swift build`
- `swiftlint`
- `bundle exec fastlane ios test_revenuecatui`
- `bundle exec fastlane ios run_api_tests`
```

Keep unchecked checklist items unchecked unless the work actually created follow-up issues.

- [ ] **Step 4: Push**

Run:

```bash
git push -u origin <branch-name>
```

Open a draft PR against `main`.

## Required test matrix

The final branch must include tests that cover every row.

| Area | Required tests |
| --- | --- |
| Schema | decode, encode, missing required protocol version, unsupported protocol version preserved for renderer fallback, fallback decode, hash/equality |
| Cache warming | web view URL is not image/video cached |
| URL validation | valid HTTPS accepted; http/file/custom/missing-host/template syntax rejected |
| Public values | string, number, bool, null, array, object, Codable round trips, depth limit |
| Envelope | snake-case keys, wrong channel drop, size limit, depth limit, JS escaping |
| Origin | default port normalization, case-insensitive host, scheme/port mismatch |
| Handshake | connect-init, version reject, frames before init dropped |
| Fit sizing | fit envelope after init, only fit axes included |
| Variables | request response echoes id/type, message reply uses rc:variables, payload flat, locale is BCP-47 hyphenated |
| App messages | step loaded, step complete responses, error, unknown drop |
| Resize | updates measured fit axes, clamps values, ignores invalid values, never reaches app handler |
| Outbound | `postVariables`, `postMessage`, reserved locale stripping, origin-gated delivery |
| Isolation | exact rule policy, identifier version, compile-once behavior, fail-closed behavior |
| Navigation | same-origin main-frame allowed, cross-origin main-frame canceled, subframes allowed |
| Load failure | HTTP 400+ fallback, benign cancellation ignored, non-benign main-frame failure fallback |
| Rendering | invalid URL fallback, unsupported protocol fallback, invisible renders nothing, unsupported WebKit platform fallback/no-op, no fallback empty, fit-height frame |
| API | Swift API tester compiles; swiftinterface baselines updated when needed |

## Definition of done

An implementation agent may call the rebuild complete only after fresh evidence for each item exists:

- [ ] `swift build` exits 0.
- [ ] `swiftlint` exits 0.
- [ ] `bundle exec fastlane ios test_revenuecatui` exits 0 locally or the PR CI lane exits 0.
- [ ] `bundle exec fastlane ios run_api_tests` exits 0 locally or the PR CI lane exits 0.
- [ ] `rg -n "rcWebViewMessage|rcWebViewHeight|RevenueCatWebView|__revenueCatReceiveMessage|__rcMeasureHeight|__rcReportHeight" RevenueCatUI Tests Sources -g "*.swift"` returns no results.
- [ ] `rg -n "VariableHandlerV2|customPaywallVariables" RevenueCatUI/Templates/V2/Components/WebView -g "*.swift"` returns no results.
- [ ] The PR body lists every verification command with pass/fail status.
- [ ] The implementation is in smaller focused commits matching the task boundaries above.

If any item is not satisfied, the agent must keep looping on the failing task instead of summarizing the branch as complete.
