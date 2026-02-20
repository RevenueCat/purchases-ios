# purchases-ios — Development Guidelines

This file provides guidance to AI coding agents when working with code in this repository.

## Project Overview

RevenueCat's official iOS SDK for in-app purchases and subscriptions. Supports iOS, macOS, tvOS, watchOS, and visionOS.

**Related repositories:**
- **Android SDK**: https://github.com/RevenueCat/purchases-android
- **Flutter SDK**: https://github.com/RevenueCat/purchases-flutter
- **React Native SDK**: https://github.com/RevenueCat/react-native-purchases
- **Hybrid Common**: https://github.com/RevenueCat/purchases-hybrid-common — shared layer for hybrid SDKs

When implementing features or debugging, check these repos for reference and patterns.

## Important: Public API Stability

**Do NOT introduce breaking changes to the public API.** The SDK is used by thousands of apps.

**Safe changes:**
- Adding new optional parameters to existing methods
- Adding new classes, methods, or properties
- Bug fixes that don't change method signatures
- Internal implementation changes

**Requires explicit approval:**
- Removing or renaming public classes/methods/properties
- Changing method signatures (parameter types, required params)
- Changing return types
- Modifying behavior in ways that break existing integrations

**Do NOT add new `public enum` types.** This SDK does not use library evolution mode, so all Swift types are `@frozen` by default. This means adding a new case to an existing `public enum` is a **source-breaking change** — any consumer with an exhaustive `switch` will fail to compile. Use structs with static constants or other patterns instead when exposing new option sets or categories.

The `Tests/APITesters/` targets run in CI to catch unintended API changes. The `api/*.swiftinterface` files track the public API surface. **If API tests fail, you've likely broken the public API.**

### Objective-C Compatibility

Many core SDK classes are exposed to Objective-C and must stay compatible. Key rules:

- **`NSObject` subclasses** (`Purchases`, `CustomerInfo`, `EntitlementInfo`, `StoreProduct`, `StoreTransaction`, etc.) must remain `@objc`-compatible. Don't add Swift-only types (e.g., generics, `async` without a completion-handler wrapper, Swift enums without `@objc`, default parameter values) to their public API without providing an Obj-C equivalent.
- **`@objc(RC...)` prefixed names** are used for Obj-C class names (e.g., `@objc(RCPurchases)`, `@objc(RCCustomerInfo)`). Don't remove or change these.
- **New public properties/methods** on `@objc`-exposed classes must be marked `@objc` unless there's a deliberate reason to exclude them (document why).
- **Enums** exposed to Obj-C use `@objc` with `Int` raw values. Swift-only enums with associated values or string raw values can't be used from Obj-C.
- **Both Swift and Obj-C API testers exist** in `Tests/APITesters/`. When modifying public API on an `@objc` class, update both `SwiftAPITester` and `ObjcAPITester` targets.
- **Don't break existing Obj-C callers** — if a method is currently callable from Obj-C, it must remain so.

## Common Development Commands

Quick reference for the most common operations:

```bash
swift build                        # Build via SPM
swift test                         # Run unit tests via SPM
tuist generate                     # Generate Tuist workspace (preferred)
swiftlint                          # Run linter
swiftlint --fix                    # Auto-fix lint issues
bundle exec fastlane test_ios      # Run iOS tests via Fastlane
bundle exec fastlane run_api_tests # Verify public API surface
```

For the full set of build, test, Tuist, and Fastlane commands, see:
- **`Contributing/CONTRIBUTING.md`** — environment setup, workflow, style guide
- **`Contributing/DEVELOPMENT.md`** — Tuist workspace generation, targets, troubleshooting
- **`fastlane/README.md`** — complete list of available Fastlane lanes

## Project Architecture

### Module Structure

This is a multi-target Swift project supporting iOS, macOS, tvOS, watchOS, and visionOS:

- **`RevenueCat`** (`Sources/`) — Core SDK: API, business logic, networking, StoreKit abstractions
- **`RevenueCat_CustomEntitlementComputation`** (`CustomEntitlementComputation/` → symlink to `Sources/`) — Same source with `ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION` flag
- **`ReceiptParser`** (`LocalReceiptParsing/` → symlink to `Sources/LocalReceiptParsing/`) — Local receipt parsing library
- **`RevenueCatUI`** (`RevenueCatUI/`) — SwiftUI paywalls and customer center (depends on `RevenueCat`)

Key top-level directories: `Sources/`, `RevenueCatUI/`, `Tests/`, `Examples/`, `Projects/`, `api/`, `fastlane/`, `Tuist/`, `Contributing/`, `scripts/`. Explore the filesystem directly for current subdirectory layout.

### Key Architectural Patterns

#### Core Purchases Module
- **Singleton Pattern**: `Purchases.shared` as the main entry point
- **Delegate Pattern**: `PurchasesDelegate` for event callbacks
- **Manager Pattern**: `IdentityManager`, `SubscriberAttributesManager`, `EventsManager`
- **Backend/Cache Layer**: `Backend` for networking, `DeviceCache` for local storage
- **StoreKit 1 / StoreKit 2 dual implementation**: The SDK maintains parallel code paths in `Sources/Purchasing/StoreKit1/` and `Sources/Purchasing/StoreKit2/`, with shared abstractions in `Sources/Purchasing/StoreKitAbstractions/`. Bug fixes or behavior changes often need to be applied to both paths. Always check whether the other StoreKit implementation is affected.

#### RevenueCatUI Module
- **SwiftUI-based**: Modern declarative UI
- **MVVM Pattern**: ViewModels with SwiftUI views
- **Main Components**: `PaywallView`, `CustomerCenterView`

### Thread Safety

The SDK is heavily concurrent — StoreKit callbacks, delegate calls, caching, and network responses can all arrive on different threads. See **`Contributing/ThreadSafety.md`** for the full guide. Key primitives:

- **`Lock`** / **`Lock(.recursive)`** — low-level synchronization for critical sections
- **`Atomic<T>`** — thread-safe wrapper for mutable state
- **`SynchronizedUserDefaults`** — thread-safe `UserDefaults` access (used by `DeviceCache`)

When modifying internal state, use these primitives. Don't introduce bare property access to shared mutable state without synchronization.

### API Annotations
- **`@_spi(Internal)`** — APIs that are public only to be accessible by other modules or hybrid SDKs, not intended for external developer use
- **`@available`** — platform availability annotations for StoreKit 2 and other iOS version-specific features

## Testing

Tests use **XCTest**, **Nimble**, **swift-snapshot-testing**, and **OHHTTPStubs**. Test targets live under `Tests/` — explore subdirectories directly for the current layout.

## Development Workflow

For environment setup, see **`Contributing/CONTRIBUTING.md`**. For code style, see **`Contributing/SwiftStyleGuide.swift`**.

### Main Entry Points
- **`Purchases`** class: Primary SDK entry point (`Sources/Purchasing/Purchases/Purchases.swift`)
- **`Purchases.configure(withAPIKey:)`**: Configuration method
- **UI Components**: `PaywallView`, `CustomerCenterView` in RevenueCatUI

### Key Dependencies
- **Swift**: Primary language with async/await support
- **StoreKit / StoreKit 2**: Apple's in-app purchase framework
- **SwiftUI**: UI framework for RevenueCatUI
- **Foundation**: Core Apple framework

## Build Configuration

### Package Manager Support
- **Swift Package Manager**: `Package.swift` (primary)
- **CocoaPods**: `RevenueCat.podspec`, `RevenueCatUI.podspec`
- **Carthage**: Supported via XCFramework

### Tuist Project Management

The project uses **Tuist** for managing the Xcode workspace. See **`Contributing/DEVELOPMENT.md`** for full Tuist commands, environment variables, and troubleshooting.

### Target Specifications
- **Minimum Deployment**: iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, visionOS 1.0
- **Swift**: 5.9+
- **Xcode**: 15.0+

These minimums are enforced at compile time. Concretely:
- **Don't use APIs unavailable on the minimum target** without an `@available` check and a fallback path (e.g., `AttributedString` is iOS 15+, Swift concurrency back-deployment requires iOS 13+ but some features need iOS 15+).
- **StoreKit 2** is iOS 15+ — all SK2 code paths must be gated with `@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)` or equivalent.
- **Never assume the latest OS** — CI tests run on multiple OS versions, and customers run the SDK on older devices.

## Development Notes

For snapshot testing, sample applications, pre-commit hooks, and release process details, see the docs in **`Contributing/`** (in particular `CONTRIBUTING.md`, `DEVELOPMENT.md`, and `RELEASING.md`).

### Important Files
- `.version` - Current SDK version
- `Local.xcconfig` - Local development configuration (not committed)
- `CI.xcconfig` - CI-specific configuration
- `api/*.swiftinterface` - Public API surface tracking

### Pull Request Labels

When creating a pull request, **always add one of these labels** to categorize the change. These labels determine automatic version bumps and changelog generation:

| Label | When to Use |
|-------|-------------|
| `pr:feat` | New user-facing features or enhancements |
| `pr:fix` | Bug fixes |
| `pr:other` | Internal changes, refactors, CI, docs, or anything that shouldn't trigger a release |

**Additional scope labels** (add alongside the primary label above):
- `pr:RevenueCatUI` — Changes specific to the RevenueCatUI module (paywalls, customer center)
- `feat:Paywalls_V2` — Changes related to Paywalls V2 (requires `pr:RevenueCatUI` as well)
- `feat:Customer Center` — Changes related to Customer Center (requires `pr:RevenueCatUI` as well)

## Code Review Guidelines

When reviewing a pull request:

1. **Check for linked specs** — If the PR description contains a link to `https://github.com/RevenueCat/sdk-specs`, fetch and read the spec before reviewing the code. The spec defines the expected behavior and requirements.
2. **Verify the implementation matches the spec** — Ensure the code implements what the spec describes, including edge cases and error handling.
3. **Check cross-platform consistency** — If the spec applies to multiple platforms, verify the implementation follows patterns from other SDKs (especially purchases-android).

## When the Task is Ambiguous

1. Search for similar existing implementation in this repo first
2. Check purchases-android and purchases-hybrid-common for patterns
3. If there's a pattern, follow it exactly
4. If not, propose options with tradeoffs and pick the safest default

## Guardrails

- **Don't invent APIs or file paths** — verify they exist before referencing them
- **Don't remove code you don't understand** — ask for context first
- **Don't make large refactors** unless explicitly requested
- **Keep diffs minimal** — only touch what's necessary, preserve existing formatting
- **Don't break the public API** — if API tests fail, investigate why
- **Fix root causes** — don't add workarounds or suppress errors without understanding the underlying issue
- **Verify changes build** — run `swift build` or the relevant Fastlane lane before considering work done
- **Run SwiftLint** before committing (`swiftlint` or `swiftlint --fix`)
- **Follow the style guide** in `Contributing/SwiftStyleGuide.swift`
- **Check Android SDK** when unsure about cross-platform implementation details — new features should follow existing patterns across SDKs
- **Never commit Claude-related files** — do not stage or commit `.claude/` directory, `settings.local.json`, or any AI tool configuration files
- **Never commit API keys or secrets** — do not stage or commit API keys, tokens, credentials, or any sensitive data
