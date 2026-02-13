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

The `Tests/APITesters/` targets run in CI to catch unintended API changes. The `api/*.swiftinterface` files track the public API surface. **If API tests fail, you've likely broken the public API.**

## Common Development Commands

### Building and Testing
```bash
# Build using Swift Package Manager
swift build

# Run unit tests using Swift Package Manager
swift test

# Build using Xcode (recommended for full project)
xcodebuild -workspace RevenueCat.xcworkspace -scheme RevenueCat -destination 'platform=iOS Simulator,name=iPhone 15'

# Run unit tests via Xcode
xcodebuild test -workspace RevenueCat.xcworkspace -scheme RevenueCat -destination 'platform=iOS Simulator,name=iPhone 15'

# Generate Tuist workspace (for full project with examples)
tuist generate

# Build Tuist workspace
xcodebuild -workspace RevenueCat-Tuist.xcworkspace -scheme RevenueCat -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Code Quality and Analysis
```bash
# Run SwiftLint
swiftlint

# Run SwiftLint with auto-correct
swiftlint --fix

# Setup development environment (installs SwiftLint, links pre-commit hooks)
bundle exec fastlane setup_dev
```

### Fastlane Commands
```bash
# Setup development environment
bundle exec fastlane setup_dev

# Run iOS tests
bundle exec fastlane test_ios

# Run tvOS tests
bundle exec fastlane test_tvos

# Run watchOS tests
bundle exec fastlane test_watchos

# Run macOS tests
bundle exec fastlane mac test_macos

# Run RevenueCatUI tests
bundle exec fastlane test_revenuecatui

# Run API tests (builds APITester targets to verify public API)
bundle exec fastlane run_api_tests

# Run backend integration tests
bundle exec fastlane backend_integration_tests

# Fetch snapshot repositories
bundle exec fastlane fetch_snapshots
```

### Snapshot Testing
```bash
# Generate RevenueCat snapshots (triggers CircleCI job)
bundle exec fastlane generate_snapshots_RC

# Generate RevenueCatUI snapshots (triggers CircleCI job)
bundle exec fastlane generate_snapshots_RCUI

# Locally generate snapshots (set environment variable)
CIRCLECI_TESTS_GENERATE_SNAPSHOTS=true bundle exec fastlane test_ios
CIRCLECI_TESTS_GENERATE_REVENUECAT_UI_SNAPSHOTS=true bundle exec fastlane test_revenuecatui
```

## Project Architecture

### Code Structure
```
purchases-ios/
├── Sources/                  # Core RevenueCat SDK source code
├── RevenueCatUI/             # SwiftUI Paywalls & Customer Center module
├── Tests/                    # All test targets
│   ├── UnitTests/            # Core SDK unit tests
│   ├── RevenueCatUITests/    # UI snapshot and unit tests
│   ├── StoreKitUnitTests/    # StoreKit-specific tests
│   ├── BackendIntegrationTests/ # Backend integration tests
│   ├── APITesters/           # API surface verification
│   └── TestingApps/          # Test applications
├── Examples/                 # Sample applications
│   ├── MagicWeather/         # UIKit sample
│   ├── MagicWeatherSwiftUI/  # SwiftUI sample
│   └── ...
├── Projects/                 # Tuist-managed projects
├── api/                      # Public API .swiftinterface files
├── fastlane/                 # CI/CD automation
├── Tuist/                    # Tuist configuration and helpers
├── Contributing/             # Contributing guides and style guide
└── scripts/                  # Build and utility scripts
```

### Module Structure
This is a multi-target Swift project supporting iOS, macOS, tvOS, watchOS, and visionOS:

- **`RevenueCat`** (`Sources/`) - Core SDK containing main API, business logic, networking, StoreKit abstractions
- **`RevenueCat_CustomEntitlementComputation`** (`CustomEntitlementComputation/` → symlink to `Sources/`) - Custom entitlement computation variant (same source with `ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION` flag)
- **`ReceiptParser`** (`LocalReceiptParsing/` → symlink to `Sources/LocalReceiptParsing/`) - Local receipt parsing library
- **`RevenueCatUI`** (`RevenueCatUI/`) - SwiftUI module for paywalls and customer center (depends on `RevenueCat`)

### Source Directory Structure
```
Sources/
├── Ads/                    # Ad attribution handling
├── Attribution/            # Attribution tracking
├── Caching/                # Local caching and persistence
├── CodableExtensions/      # JSON encoding/decoding helpers
├── CustomerCenter/         # Customer center functionality
├── DeepLink/               # Deep link handling
├── Diagnostics/            # SDK diagnostics
├── Error Handling/         # Error types and handling
├── Events/                 # Event tracking
├── FoundationExtensions/   # Foundation type extensions
├── Identity/               # User identity management
├── LocalReceiptParsing/    # Receipt parsing
├── Logging/                # Logging infrastructure
├── Misc/                   # Miscellaneous utilities
├── Networking/             # HTTP client and API communication
├── OfflineEntitlements/    # Offline entitlement support
├── Paywalls/               # Paywall data models
├── Purchasing/             # Core purchasing logic (Purchases class lives here)
├── Security/               # Security utilities
├── SubscriberAttributes/   # Subscriber attributes
├── Support/                # Support utilities
├── Virtual Currencies/     # Virtual currency support
└── WebPurchaseRedemption/  # Web purchase redemption
```

### Key Architectural Patterns

#### Core Purchases Module
- **Singleton Pattern**: `Purchases.shared` as the main entry point
- **Delegate Pattern**: `PurchasesDelegate` for event callbacks
- **Manager Pattern**: `IdentityManager`, `SubscriberAttributesManager`, `EventsManager`
- **Backend/Cache Layer**: `Backend` for networking, `DeviceCache` for local storage

#### RevenueCatUI Module
- **SwiftUI-based**: Modern declarative UI
- **MVVM Pattern**: ViewModels with SwiftUI views
- **Main Components**: `PaywallView`, `CustomerCenterView`

### API Annotations
- **`@_spi(Internal)`** - APIs that are public only to be accessible by other modules or hybrid SDKs, not intended for external developer use
- **`@available`** - Platform availability annotations for StoreKit 2 and other iOS version-specific features

## Testing Framework

### Technologies Used
- **XCTest** - Primary testing framework
- **Nimble** - Fluent assertions and matchers
- **swift-snapshot-testing** - Snapshot testing for UI
- **OHHTTPStubs** - Network stubbing (via Tuist dependencies)

### Test Structure
```
Tests/
├── APITesters/              # API surface verification tests
├── BackendIntegrationTests/ # Backend integration tests
├── InstallationTests/       # Installation verification (Carthage, CocoaPods, SPM)
├── ReceiptParserTests/      # Receipt parser unit tests
├── RevenueCatUITests/       # RevenueCatUI snapshot and unit tests
├── StoreKitUnitTests/       # StoreKit-specific unit tests
├── TestPlans/               # Xcode test plans
├── TestingApps/             # Test applications
│   ├── PaywallsTester/      # Paywall testing app
│   ├── PurchaseTesterSwiftUI/ # Purchase tester (SwiftUI)
│   └── ...
└── UnitTests/               # Core SDK unit tests
```

### Running Tests
- **Unit Tests**: Select "All Tests" scheme in Xcode and press `Cmd+U`
- **Specific Test Plans**: Use test plans in `Tests/TestPlans/` directory
- **CI Test Plans**: `CI-RevenueCat`, `CI-RevenueCat-Snapshots`, `CI-RevenueCatUI`

## Development Workflow

### Environment Setup
1. Install mise: `brew install mise`
2. Run `mise install` in project root (installs Tuist and SwiftLint)
3. Run `bundle install` for Fastlane
4. Run `bundle exec fastlane setup_dev` to link pre-commit hooks
5. Copy `Local.xcconfig.SAMPLE` to `Local.xcconfig` and configure API keys

### Code Quality
- **SwiftLint**: Static code analysis with custom rules (`.swiftlint.yml`)
- **Pre-commit Hook**: Runs SwiftLint before each commit
- **API Compatibility**: Swift interface files in `api/` directory track public API changes
- **Style Guide**: See `Contributing/SwiftStyleGuide.swift`

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
The project uses **Tuist** for managing the Xcode workspace with examples and test apps.

**Basic Commands:**
```bash
# Generate workspace (required before building with Tuist)
tuist generate

# Clean generated files
tuist clean

# Edit project configuration
tuist edit
```

**Configuration Files:**
- `Workspace.swift` - Defines which projects to include in the workspace
- `Tuist.swift` - Global Tuist configuration
- `Tuist/` directory - Contains Package.swift for SPM dependencies and project helpers

**Environment Variables:**
- `TUIST_RC_LOCAL=true` - Include local RevenueCat/RevenueCatUI projects (default for local dev)
- `TUIST_RC_LOCAL=false` - Use SPM dependency (for load shedder tests)
- `TUIST_INCLUDE_XCFRAMEWORK_INSTALLATION_TESTS=true` - Include XCFramework installation tests

**Projects Included (via `Workspace.swift`):**
- `Examples/rc-maestro/` - Maestro E2E test app
- `Examples/MagicWeather/` - UIKit sample app
- `Examples/MagicWeatherSwiftUI/` - SwiftUI sample app
- `Examples/testCustomEntitlementsComputation/` - Custom entitlement computation sample
- `Examples/PurchaseTester/` - Legacy purchase tester
- `Projects/PaywallsTester/` - Paywall testing app
- `Projects/APITesters/` - API surface verification
- `Projects/PaywallValidationTester/` - Paywall validation tests
- `Projects/BinarySizeTest/` - SDK binary size measurement
- `Projects/RCTTester/` - Additional testing app

### Target Specifications
- **Minimum Deployment**: iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, visionOS 1.0
- **Swift**: 5.9+
- **Xcode**: 15.0+

## Development Notes

### Snapshot Testing
- Snapshots stored in external repository: `purchases-ios-snapshots`
- Commit hash tracked in `Tests/purchases-ios-snapshots-commit`
- Run `bundle exec fastlane fetch_snapshots` before running snapshot tests locally
- RevenueCatUI snapshots use `swift-snapshot-testing` library

### Sample Applications
- **MagicWeather**: UIKit sample app
- **MagicWeatherSwiftUI**: SwiftUI sample app
- **PurchaseTester**: Purchase flow testing
- **PaywallsTester**: Paywall UI testing
- **testCustomEntitlementsComputation**: Custom entitlement computation sample

### Pre-commit Hook
The pre-commit hook (`scripts/pre-commit.sh`) runs SwiftLint on staged files. Set up via:
```bash
bundle exec fastlane setup_dev
```

### Release Process
- **Fastlane**: Automated release management
- **Version Management**: Centralized in `.version` file
- **Publishing**: CocoaPods, SPM, Carthage (XCFramework)
- **Documentation**: DocC for API docs

### Important Files
- `.version` - Current SDK version
- `Local.xcconfig` - Local development configuration (not committed)
- `CI.xcconfig` - CI-specific configuration
- `api/*.swiftinterface` - Public API surface tracking

## When the Task is Ambiguous

1. Search for similar existing implementation in this repo first
2. Check purchases-android and purchases-hybrid-common for patterns
3. If there's a pattern, follow it exactly
4. If not, propose options with tradeoffs and pick the safest default

## Guardrails

- **Don't invent APIs or file paths** — verify they exist
- **Don't remove code you don't understand** — ask for context
- **Don't make large refactors** unless explicitly requested
- **Keep diffs minimal** — preserve existing formatting
- **Don't break the public API** — if API tests fail, investigate why
- **Check Android SDK** when unsure about cross-platform implementation details
- **Run SwiftLint** before committing (`swiftlint` or `swiftlint --fix`)
- **Follow the style guide** in `Contributing/SwiftStyleGuide.swift`

## Core Principles

- **Simplicity First**: Make every change as simple as possible. Impact minimal code.
- **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
- **Minimal Impact**: Changes should only touch what's necessary. Avoid introducing bugs.
- **Test Your Work**: Always verify changes work before marking done.
- **Cross-Platform Consistency**: Check Android SDK for patterns when implementing new features.
