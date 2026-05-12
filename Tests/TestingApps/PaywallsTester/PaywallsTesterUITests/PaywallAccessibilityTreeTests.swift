/*
 PaywallAccessibilityTreeTests
 ==============================
 Captures the XCUITest accessibility tree of a rendered paywall and exports it
 as a structured JSON file conforming to the PaywallLayoutTree schema.

 OUTPUT FORMAT
 -------------
 The JSON contains a flat `components` dictionary keyed by component ID
 (the accessibility identifier set on each rendered element). All frame
 coordinates are integers in the coordinate system of the paywall root — i.e.
 (0, 0) is the top-left corner of the paywall content area.

 When the same component ID appears on multiple elements (unusual but possible),
 the entries are disambiguated with a numeric suffix: "id_0", "id_1", …

 Only elements that carry a non-empty accessibility identifier are included.

 This test target is attached to the PaywallsTester app. It can navigate via three paths:

 A) Hermetic local offering (no API key, no network) — set LOCAL_OFFERINGS_PATH to
    a local `offerings.json` and OFFERING_ID to one of the offerings inside it.
    The PaywallsTester app loads the offering via `LocalOfferingLoader` and presents it.
 B) Live Paywalls tab (API key required) — loads a specific offering by ID from
    the RevenueCat backend and opens its paywall.
 C) Examples tab (no API key, no LOCAL_OFFERINGS_PATH) — opens the first V1 template paywall.

 HOW TO RUN
 ----------

 Hermetic (preferred for CI / cross-platform parity tests):

      TEST_RUNNER_LOCAL_OFFERINGS_PATH=/path/to/offerings.json \
      TEST_RUNNER_OFFERING_ID=my-v2-offering \
      xcodebuild test \
        -workspace Tests/TestingApps/PaywallsTester/PaywallsTester.xcworkspace \
        -scheme "PaywallAccessibilityTreeTests" \
        -destination 'platform=iOS Simulator,name=iPhone 17'

 Live Paywalls tab (V2 paywall by offering ID):

      TEST_RUNNER_RC_API_KEY=appl_xxx TEST_RUNNER_OFFERING_ID=my-v2-offering xcodebuild test \
        -workspace Tests/TestingApps/PaywallsTester/PaywallsTester.xcworkspace \
        -scheme "PaywallAccessibilityTreeTests" \
        -destination 'platform=iOS Simulator,name=iPhone 17'

 Examples tab (default, no API key):

      xcodebuild test \
        -workspace Tests/TestingApps/PaywallsTester/PaywallsTester.xcworkspace \
        -scheme "PaywallAccessibilityTreeTests" \
        -destination 'platform=iOS Simulator,name=iPhone 17'

   LOCAL_OFFERINGS_PATH — path to a local `offerings.json`; bypasses the RevenueCat backend.
                          Asset URLs are rewritten to file:// URLs adjacent to the JSON;
                          see LocalOfferingLoader.swift for the convention.
   OFFERING_ID          — offering to open; required when RC_API_KEY or LOCAL_OFFERINGS_PATH is set.
                          When omitted without RC_API_KEY, defaults to "examples-first".
   RC_API_KEY           — RevenueCat API key; triggers the Live Paywalls navigation path.

 Per-device parameterization (single-device per invocation; outer scripts handle device matrices):

   DEVICE_CLASS         — free-text label stored verbatim in metadata.deviceClass
                          (e.g. "tablet", "tablet-landscape", "mini", "dynamic-island").
   DEVICE_ORIENTATION   — "portrait" (default) | "landscape". Rotates via XCUIDevice.
   COLOR_SCHEME         — "light" (default) | "dark". Applied via .preferredColorScheme().
   TEST_LOCALE          — BCP-47 locale, e.g. "en_US" (default), "de_DE", "ja_JP".

 Artifact location:

   TEST_ARTIFACTS_DIR   — override output directory. Default is
                          $HOST_PROJECT_DIR/fastlane/test_output/xctest/paywall-accessibility-tree/
                          (auto-resolved from SIMULATOR_HOST_HOME if not provided).
   DEV_DESKTOP_COPY=1   — also write a copy to ~/Desktop on the host (local dev convenience).

 OUTPUT
 ------
 Two files written to the resolved artifact directory:
   paywall-tree-<offering-id>-<timestamp>.json  — flat component dictionary (PaywallLayoutTree)
   paywall-tree-<offering-id>-<timestamp>.png   — full-app screenshot at capture time

 Both files are also attached to the .xcresult bundle via XCTAttachment.

 The JSON conforms to the PaywallLayoutTree schema at:
   https://revenuecat.com/schemas/paywall-layout-tree.json
*/

import XCTest

final class PaywallAccessibilityTreeTests: XCTestCase {

    private static let appLaunchTimeout: TimeInterval = 20
    private static let paywallLoadTimeout: TimeInterval = 15
    private static let offeringsLoadTimeout: TimeInterval = 30

    // MARK: - Schema version

    private static let extractorVersion = "2.4.0"

    // MARK: - Test

    func testCaptureAccessibilityTree() throws {
        let env = ProcessInfo.processInfo.environment
        let paywallId = env["OFFERING_ID"] ?? "examples-first"
        let localPath = env["LOCAL_OFFERINGS_PATH"]
        let apiKey = env["RC_API_KEY"]
        let deviceClass = env["DEVICE_CLASS"]
        let orientation = (env["DEVICE_ORIENTATION"] ?? "portrait").lowercased()
        let colorScheme = (env["COLOR_SCHEME"] ?? "light").lowercased()
        let testLocale = env["TEST_LOCALE"] ?? "en_US"

        let app = XCUIApplication()

        // The simulator occasionally interrupts the paywall with a system "Sign in to
        // Apple Account" dialog when running in hermetic mode (where the SDK isn't talking
        // to the App Store). Dismiss it automatically so the screenshot captures the paywall.
        // The monitor must be installed before `app.launch()`.
        let interruptionMonitor = addUIInterruptionMonitor(withDescription: "Apple Account") { alert in
            let cancelButton = alert.buttons["Cancel"]
            if cancelButton.exists {
                cancelButton.tap()
                return true
            }
            return false
        }
        defer { removeUIInterruptionMonitor(interruptionMonitor) }

        // Pass through navigation-relevant env vars to the app.
        if let localPath = localPath {
            app.launchEnvironment["LOCAL_OFFERINGS_PATH"] = localPath
            app.launchEnvironment["OFFERING_ID"] = paywallId
        } else if let apiKey = apiKey {
            app.launchEnvironment["REVENUECAT_API_KEY"] = apiKey
            app.launchEnvironment["OFFERING_ID"] = paywallId
        }
        // Suppress web-checkout URL opens so the paywall stays on screen for the screenshot.
        // PaywallPresenter injects a no-op openURL action when this flag is set.
        app.launchEnvironment["SCREENSHOT_MODE"] = "1"
        // Plumb the color-scheme override to PaywallPresenter.
        app.launchEnvironment["COLOR_SCHEME"] = colorScheme

        // Locale overrides — applied via the documented launch-argument hook.
        let language = String(testLocale.prefix(while: { $0 != "_" && $0 != "-" }))
        app.launchArguments += ["-AppleLanguages", "(\(language))", "-AppleLocale", testLocale]

        app.launch()

        if localPath != nil || apiKey != nil {
            try navigateToLivePaywall(in: app, id: paywallId)
        } else {
            try navigateToExamplesPaywall(in: app, id: paywallId)
        }

        // Apply orientation override after the paywall is on screen so SwiftUI re-lays
        // out the components against the new viewport before we capture.
        if orientation == "landscape" {
            XCUIDevice.shared.orientation = .landscapeLeft
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Explicitly dismiss any "Sign in to Apple Account" dialog that the system pops
        // up when StoreKit isn't authenticated. The UIInterruptionMonitor only fires on
        // user interaction, so we proactively look for and dismiss the alert here.
        dismissSystemAccountAlertIfPresent(in: app)
        // Tap into the app to give the UIInterruptionMonitor a chance to consume any
        // alert it caught.
        app.tap()

        // Let SwiftUI layout and sheet animation fully settle.
        // Web-checkout URL opens are suppressed via SCREENSHOT_MODE=1 (see PaywallPresenter),
        // so the paywall remains on screen for the full duration of this sleep.
        Thread.sleep(forTimeInterval: 2)

        // Capture the screenshot while the paywall is fully rendered and on screen.
        let screenshot = app.screenshot()
        let pngData = screenshot.pngRepresentation

        // Take the full app snapshot for metadata (viewport).
        let appSnapshot = try app.snapshot()

        // Resolve the paywall root.
        // Identifier-based lookup is unreliable: SwiftUI transparent containers propagate
        // `.accessibilityIdentifier` to their first leaf child, and paywall component JSON
        // IDs can collide with the "paywall" identifier anyway.
        //
        // Instead, walk down the tree by always following the child with the most descendants.
        // When the path reaches a node with more than 2 direct children, we've arrived at
        // the actual paywall content (app chrome and wrapper containers each have 1–2 children).
        let paywallSnapshot: any XCUIElementSnapshot = findPaywallRoot(in: appSnapshot)

        // Build flat component dictionary, with coordinates relative to the paywall root.
        let components = buildComponents(from: paywallSnapshot)

        // Read the safe-area insets from the test-only probe element injected by
        // PaywallsV2View.safeAreaProbe. Best-effort; missing on non-V2 paywalls.
        let safeAreaInsets = readSafeAreaInsets(in: app)

        // Build metadata
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let platformVersion = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        let appFrame = appSnapshot.frame
        let rootCGFrame = paywallSnapshot.frame

        let metadata = PaywallLayoutTree.Metadata(
            platform: "ios",
            platformVersion: platformVersion,
            viewport: PaywallLayoutTree.Metadata.Viewport(
                width: Self.roundToInt(appFrame.width),
                height: Self.roundToInt(appFrame.height),
                scale: screenScale()
            ),
            rootFrame: Self.normalizeFrame(rootCGFrame),
            safeAreaInsets: safeAreaInsets,
            offeringId: paywallId,
            locale: testLocale,
            deviceClass: deviceClass,
            colorScheme: colorScheme,
            orientation: orientation,
            extractorVersion: Self.extractorVersion,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )

        let tree = PaywallLayoutTree(metadata: metadata, components: components)

        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(tree)

        // Build filename stem (shared by .json and .png)
        let safe = paywallId
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let stem = "paywall-tree-\(safe)-\(timestamp)"
        let jsonFilename = "\(stem).json"
        let pngFilename = "\(stem).png"

        // Resolve the on-disk artifact location.
        let artifactDir = Self.resolveArtifactDirectory()
        try? FileManager.default.createDirectory(at: artifactDir, withIntermediateDirectories: true)

        let jsonURL = artifactDir.appendingPathComponent(jsonFilename)
        let pngURL = artifactDir.appendingPathComponent(pngFilename)
        try jsonData.write(to: jsonURL)
        try pngData.write(to: pngURL)

        // Optional ~/Desktop copy for local development.
        if env["DEV_DESKTOP_COPY"] == "1",
           let hostHome = env["SIMULATOR_HOST_HOME"], !hostHome.contains("CoreSimulator") {
            let desktopDir = URL(fileURLWithPath: hostHome).appendingPathComponent("Desktop")
            try? jsonData.write(to: desktopDir.appendingPathComponent(jsonFilename))
            try? pngData.write(to: desktopDir.appendingPathComponent(pngFilename))
            print("  Desktop copy: \(desktopDir.appendingPathComponent(jsonFilename).path)")
            print("  Desktop copy: \(desktopDir.appendingPathComponent(pngFilename).path)")
        }

        // Always attach both files to the .xcresult bundle — extractable via `xcrun xcresulttool`
        let jsonAttachment = XCTAttachment(data: jsonData, uniformTypeIdentifier: "public.json")
        jsonAttachment.name = jsonFilename
        jsonAttachment.lifetime = XCTAttachment.Lifetime.keepAlways
        add(jsonAttachment)

        let pngAttachment = XCTAttachment(data: pngData, uniformTypeIdentifier: "public.png")
        pngAttachment.name = pngFilename
        pngAttachment.lifetime = XCTAttachment.Lifetime.keepAlways
        add(pngAttachment)

        print("────────────────────────────────────────")
        print("Accessibility tree written to:")
        print("  \(jsonURL.path)")
        print("  \(pngURL.path)")
        print("────────────────────────────────────────")
    }

    // MARK: - Artifact location

    /// Returns the directory where the JSON + PNG artifacts should be written.
    ///
    /// Resolution order:
    ///   1. `TEST_ARTIFACTS_DIR` env var (absolute path)
    ///   2. `<SIMULATOR_HOST_HOME-or-HOST_PROJECT_DIR>/fastlane/test_output/xctest/paywall-accessibility-tree/`
    ///   3. `/tmp/` (fallback if no host hint available)
    private static func resolveArtifactDirectory() -> URL {
        let env = ProcessInfo.processInfo.environment
        if let override = env["TEST_ARTIFACTS_DIR"], !override.isEmpty {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        // SIMULATOR_HOST_HOME is auto-injected by XCTest; HOST_PROJECT_DIR is opt-in by caller.
        let hostHint = env["HOST_PROJECT_DIR"]
            ?? env["SIMULATOR_HOST_HOME"]
        if let host = hostHint, !host.contains("CoreSimulator") {
            return URL(fileURLWithPath: host, isDirectory: true)
                .appendingPathComponent("fastlane/test_output/xctest/paywall-accessibility-tree",
                                       isDirectory: true)
        }
        return URL(fileURLWithPath: "/tmp", isDirectory: true)
    }

    // MARK: - Coordinate normalization

    /// Banker's rounding (round-half-to-even) — Swift's `.rounded()` default,
    /// applied to convert a `CGFloat` to a deterministic `Int` for JSON output.
    private static func roundToInt(_ value: CGFloat) -> Int {
        return Int(Double(value).rounded())
    }

    private static func normalizeFrame(_ frame: CGRect) -> PaywallLayoutTree.Frame {
        return PaywallLayoutTree.Frame(
            x: roundToInt(frame.origin.x),
            y: roundToInt(frame.origin.y),
            width: roundToInt(frame.size.width),
            height: roundToInt(frame.size.height)
        )
    }

    // MARK: - System alert dismissal

    /// Looks for an "Apple Account" / StoreKit sign-in alert and taps Cancel.
    /// Best-effort; returns immediately if no such alert is present.
    private func dismissSystemAccountAlertIfPresent(in app: XCUIApplication) {
        // Springboard hosts the iOS system alerts that appear over the app.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let candidates = [
            springboard.alerts.buttons["Cancel"].firstMatch,
            springboard.buttons["Cancel"].firstMatch,
            app.alerts.buttons["Cancel"].firstMatch,
            app.buttons["Cancel"].firstMatch
        ]
        for button in candidates where button.exists && button.isHittable {
            button.tap()
            return
        }
    }

    // MARK: - Safe-area read

    /// Reads the comma-separated `top,bottom,leading,trailing` payload from the
    /// `__safe_area_insets` probe element emitted by PaywallsV2View when SCREENSHOT_MODE=1.
    /// Returns `nil` when the probe isn't present (e.g. V1 paywalls).
    private func readSafeAreaInsets(in app: XCUIApplication) -> PaywallLayoutTree.Insets? {
        let probe = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", "__safe_area_insets"))
            .firstMatch
        guard probe.waitForExistence(timeout: 1) else { return nil }
        let raw = (probe.value as? String) ?? ""
        let parts = raw.split(separator: ",").compactMap { Double($0) }
        guard parts.count == 4 else { return nil }
        return PaywallLayoutTree.Insets(
            top: Int(parts[0].rounded()),
            bottom: Int(parts[1].rounded()),
            leading: Int(parts[2].rounded()),
            trailing: Int(parts[3].rounded())
        )
    }

    // MARK: - Navigation

    /// Opens a paywall from the "Live Paywalls" tab.
    /// Requires an API key via `app.launchEnvironment["REVENUECAT_API_KEY"]` and the
    /// offering ID via `app.launchEnvironment["OFFERING_ID"]`. The app auto-opens the
    /// matching paywall as a sheet once offerings are fetched; if the sheet doesn't
    /// appear within the timeout the test falls back to tapping the row directly.
    private func navigateToLivePaywall(in app: XCUIApplication, id: String) throws {
        XCTAssertTrue(
            app.staticTexts.firstMatch.waitForExistence(timeout: Self.appLaunchTimeout),
            "App did not become ready within \(Self.appLaunchTimeout)s"
        )

        let liveTab = app.tabBars.buttons["Live Paywalls"]
        XCTAssertTrue(
            liveTab.waitForExistence(timeout: 5),
            "Live Paywalls tab not found — check that the API key is valid and Purchases is configured"
        )
        liveTab.tap()

        // The paywall view carries id="paywall" (set in addPaywallModifiers).
        // Use it as the signal that the paywall is on screen.
        let paywallElement = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == 'paywall'"))
            .firstMatch

        // Primary path: the app auto-opens the paywall sheet via fetchOfferings().
        if paywallElement.waitForExistence(timeout: Self.offeringsLoadTimeout) {
            return
        }

        // Fallback: tap the offering row directly. UICollectionView may not expose
        // off-screen button elements, but the StaticText inside each cell is accessible.
        let offeringText = app.staticTexts
            .matching(NSPredicate(format: "label == %@", id))
            .firstMatch
        XCTAssertTrue(
            offeringText.waitForExistence(timeout: 5),
            "Offering '\(id)' not found in list"
        )
        offeringText.tap()

        XCTAssertTrue(
            paywallElement.waitForExistence(timeout: Self.paywallLoadTimeout),
            "Paywall for '\(id)' did not appear within \(Self.paywallLoadTimeout)s after tap"
        )
    }

    /// Opens a paywall from the "Examples" tab (V1 templates, no API key required).
    private func navigateToExamplesPaywall(in app: XCUIApplication, id: String) throws {
        XCTAssertTrue(
            app.staticTexts.firstMatch.waitForExistence(timeout: Self.appLaunchTimeout),
            "App did not become ready within \(Self.appLaunchTimeout)s"
        )

        let examplesTab = app.tabBars.buttons["Examples"]
        if examplesTab.exists {
            examplesTab.tap()
        }

        let fullscreenButton = app.buttons["Fullscreen"].firstMatch
        let anyModeButton = app.buttons.element(matching: .button, identifier: "").firstMatch
        if fullscreenButton.waitForExistence(timeout: 5) {
            fullscreenButton.tap()
        } else if anyModeButton.waitForExistence(timeout: 5) {
            anyModeButton.tap()
        }
    }

    // MARK: - Screen scale

    /// Returns the physical pixel scale of the main screen.
    /// `XCUIScreen.main.scale` is unavailable on some SDK versions; falls back to UIScreen when
    /// available, and 2.0 otherwise (safe default for modern simulators).
    private func screenScale() -> Double {
        #if canImport(UIKit)
        return Double(UIScreen.main.scale)
        #else
        return 2.0
        #endif
    }

    // MARK: - Paywall root search

    /// Counts the total number of nodes in a snapshot subtree.
    private func subtreeSize(_ node: any XCUIElementSnapshot) -> Int {
        node.children.reduce(1) { $0 + subtreeSize($1) }
    }

    /// Walks the accessibility tree to find the paywall content root.
    ///
    /// The strategy: descend greedily by always following the child with the most descendants.
    /// Stop and return the current node when it has more than 2 direct children — that signals
    /// we've left the single-child wrapper chain (app shell, navigation containers) and reached
    /// the actual multi-element paywall content.
    ///
    /// Falls back to the full application snapshot when no multi-child node is found
    /// (e.g. a very simple paywall with only 1–2 top-level components).
    private func findPaywallRoot(in node: any XCUIElementSnapshot) -> any XCUIElementSnapshot {
        var current = node
        // Limit iterations to avoid infinite loops on degenerate trees.
        for _ in 0..<50 {
            let children = current.children
            if children.count > 2 {
                // Found the first "content" node — this is the paywall root.
                return current
            } else if children.count == 0 {
                // Leaf node with no siblings — fall back to the input.
                return node
            } else {
                // 1 or 2 children: keep descending via the richest branch.
                current = children.max(by: { subtreeSize($0) < subtreeSize($1) }) ?? children[0]
            }
        }
        return node
    }

    // MARK: - Flat component builder

    /// Builds a flat dictionary of components from the paywall snapshot.
    ///
    /// Only elements with a non-empty accessibility identifier are included.
    /// Coordinates are translated so that (0, 0) is the top-left of `rootSnapshot`.
    ///
    /// Duplicate IDs are disambiguated with a `_0`, `_1`, … suffix on every occurrence.
    private func buildComponents(
        from rootSnapshot: any XCUIElementSnapshot
    ) -> [String: PaywallLayoutTree.Component] {
        let origin = rootSnapshot.frame.origin

        // DFS: collect (id, snapshot) for every element that has an identifier.
        var pairs: [(id: String, snapshot: any XCUIElementSnapshot)] = []
        collectIdedSnapshots(rootSnapshot, into: &pairs)

        // Count how many times each ID appears.
        var idCounts: [String: Int] = [:]
        for (id, _) in pairs { idCounts[id, default: 0] += 1 }

        // For IDs that appear more than once, sort their occurrences spatially
        // (top-to-bottom, then left-to-right) so the _0/_1/… suffix assignment
        // is determined by on-screen position rather than DFS traversal order.
        // This makes the numbering stable across platforms that walk the tree in
        // different orders (iOS DFS vs. Android BFS).
        var groupedByDuplicateId: [String: [(snapshot: any XCUIElementSnapshot, dfsIndex: Int)]] = [:]
        for (dfsIndex, (id, snapshot)) in pairs.enumerated() {
            if idCounts[id]! > 1 {
                groupedByDuplicateId[id, default: []].append((snapshot, dfsIndex))
            }
        }

        // Build a map from dfsIndex → spatially-stable suffix index for duplicate IDs.
        // Frames are pre-rounded to integers so the y-comparison is exact (no tolerance).
        var spatialSuffixIndex: [Int: Int] = [:]
        for (_, occurrences) in groupedByDuplicateId {
            let sorted = occurrences.sorted {
                let aY = Self.roundToInt($0.snapshot.frame.minY)
                let bY = Self.roundToInt($1.snapshot.frame.minY)
                if aY != bY { return aY < bY }
                return Self.roundToInt($0.snapshot.frame.minX)
                    < Self.roundToInt($1.snapshot.frame.minX)
            }
            for (suffixIdx, item) in sorted.enumerated() {
                spatialSuffixIndex[item.dfsIndex] = suffixIdx
            }
        }

        // Assign dictionary keys, adding numeric suffixes for duplicates.
        var result: [String: PaywallLayoutTree.Component] = [:]

        for (dfsIndex, (id, snapshot)) in pairs.enumerated() {
            let key: String
            if idCounts[id]! > 1 {
                let idx = spatialSuffixIndex[dfsIndex, default: 0]
                key = "\(id)_\(idx)"
            } else {
                key = id
            }

            // Coordinates are stored as integers relative to the paywall root.
            // We translate the absolute snapshot frame by the root origin and then
            // round each component independently (banker's rounding).
            let cgFrame = snapshot.frame
            let frame = PaywallLayoutTree.Frame(
                x: Self.roundToInt(cgFrame.origin.x - origin.x),
                y: Self.roundToInt(cgFrame.origin.y - origin.y),
                width: Self.roundToInt(cgFrame.size.width),
                height: Self.roundToInt(cgFrame.size.height)
            )

            // Skip zero-dimension invisible placeholders (UIKit layout artefacts).
            // Note: check width OR height being zero (not both) — some artefacts have nonzero
            // width but zero height (e.g. 402×0 nav-bar remnants).
            //
            // We intentionally do NOT filter on negative-y frames here. Paywall overlay
            // components (header images, close buttons) are rendered above the paywall
            // content root in the safe-area region; their root-relative y is legitimately
            // negative. The old `frame.y < -10` guard was incorrectly removing them.
            if frame.width == 0 || frame.height == 0 {
                continue
            }

            // Filter out the test-only safe-area sentinel — it's read separately and
            // does not belong in the component dictionary.
            if id == "__safe_area_insets" {
                continue
            }

            let value: String?
            if let rawValue = snapshot.value {
                let str = "\(rawValue)"
                value = str.isEmpty ? nil : str
            } else {
                value = nil
            }

            result[key] = PaywallLayoutTree.Component(
                type: semanticType(snapshot.elementType),
                nativeType: elementTypeName(snapshot.elementType),
                componentId: id,
                label: snapshot.label.isEmpty ? nil : snapshot.label,
                value: value,
                frame: frame,
                state: .init(enabled: snapshot.isEnabled, selected: snapshot.isSelected)
            )
        }

        return result
    }

    /// DFS walk — appends every element with a non-empty identifier to `pairs`.
    ///
    /// The `"paywall"` identifier is a navigation sentinel applied to the outer wrapper view in
    /// `PaywallsV2View` so that `navigateToLivePaywall` can detect when the paywall appears on
    /// screen. Because that outer container has no `.accessibilityElement(children: .contain)`
    /// barrier, SwiftUI propagates the sentinel string down to leaf children that would otherwise
    /// have no identifier. Those entries must be excluded from the component dictionary.
    private func collectIdedSnapshots(
        _ snapshot: any XCUIElementSnapshot,
        into pairs: inout [(id: String, snapshot: any XCUIElementSnapshot)]
    ) {
        let id = snapshot.identifier
        if !id.isEmpty && id != "paywall" {
            pairs.append((id, snapshot))
        }
        for child in snapshot.children {
            collectIdedSnapshots(child, into: &pairs)
        }
    }

    // MARK: - Type mapping

    /// Maps a raw XCUITest element type to the normalized semantic type used in the schema.
    // swiftlint:disable:next cyclomatic_complexity
    private func semanticType(_ type: XCUIElement.ElementType) -> String {
        switch type {
        case .application:                                      return "application"
        case .window:                                           return "window"
        case .scrollView:                                       return "scroll"
        case .staticText, .textView:                            return "text"
        case .image:                                            return "image"
        case .button, .radioButton:                             return "button"
        case .switch, .toggle, .checkBox:                       return "toggle"
        case .textField, .secureTextField, .searchField:        return "input"
        case .icon:                                             return "icon"
        // .separator is not available in this SDK version; falls through to "container"
        default:                                                return "container"
        }
    }

    /// Returns the raw XCUITest element type name string (stored as `nativeType` in the JSON).
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func elementTypeName(_ type: XCUIElement.ElementType) -> String {
        switch type {
        case .other:               return "Other"
        case .application:         return "Application"
        case .group:               return "Group"
        case .window:              return "Window"
        case .sheet:               return "Sheet"
        case .drawer:              return "Drawer"
        case .alert:               return "Alert"
        case .dialog:              return "Dialog"
        case .button:              return "Button"
        case .radioButton:         return "RadioButton"
        case .radioGroup:          return "RadioGroup"
        case .checkBox:            return "CheckBox"
        case .disclosureTriangle:  return "DisclosureTriangle"
        case .popUpButton:         return "PopUpButton"
        case .comboBox:            return "ComboBox"
        case .menuButton:          return "MenuButton"
        case .toolbarButton:       return "ToolbarButton"
        case .popover:             return "Popover"
        case .keyboard:            return "Keyboard"
        case .key:                 return "Key"
        case .navigationBar:       return "NavigationBar"
        case .tabBar:              return "TabBar"
        case .tabGroup:            return "TabGroup"
        case .toolbar:             return "Toolbar"
        case .statusBar:           return "StatusBar"
        case .table:               return "Table"
        case .tableRow:            return "TableRow"
        case .tableColumn:         return "TableColumn"
        case .outline:             return "Outline"
        case .outlineRow:          return "OutlineRow"
        case .browser:             return "Browser"
        case .collectionView:      return "CollectionView"
        case .slider:              return "Slider"
        case .pageIndicator:       return "PageIndicator"
        case .progressIndicator:   return "ProgressIndicator"
        case .activityIndicator:   return "ActivityIndicator"
        case .segmentedControl:    return "SegmentedControl"
        case .picker:              return "Picker"
        case .pickerWheel:         return "PickerWheel"
        case .switch:              return "Switch"
        case .toggle:              return "Toggle"
        case .link:                return "Link"
        case .image:               return "Image"
        case .icon:                return "Icon"
        case .searchField:         return "SearchField"
        case .scrollView:          return "ScrollView"
        case .scrollBar:           return "ScrollBar"
        case .staticText:          return "StaticText"
        case .textField:           return "TextField"
        case .secureTextField:     return "SecureTextField"
        case .datePicker:          return "DatePicker"
        case .textView:            return "TextView"
        case .menu:                return "Menu"
        case .menuItem:            return "MenuItem"
        case .menuBar:             return "MenuBar"
        case .menuBarItem:         return "MenuBarItem"
        case .map:                 return "Map"
        case .webView:             return "WebView"
        case .incrementArrow:      return "IncrementArrow"
        case .decrementArrow:      return "DecrementArrow"
        case .timeline:            return "Timeline"
        case .ratingIndicator:     return "RatingIndicator"
        case .valueIndicator:      return "ValueIndicator"
        case .splitGroup:          return "SplitGroup"
        case .splitter:            return "Splitter"
        case .relevanceIndicator:  return "RelevanceIndicator"
        case .colorWell:           return "ColorWell"
        case .helpTag:             return "HelpTag"
        case .matte:               return "Matte"
        case .dockItem:            return "DockItem"
        case .ruler:               return "Ruler"
        case .rulerMarker:         return "RulerMarker"
        case .grid:                return "Grid"
        case .levelIndicator:      return "LevelIndicator"
        case .cell:                return "Cell"
        case .layoutArea:          return "LayoutArea"
        case .layoutItem:          return "LayoutItem"
        case .handle:              return "Handle"
        case .stepper:             return "Stepper"
        case .tab:                 return "Tab"
        case .touchBar:            return "TouchBar"
        case .statusItem:          return "StatusItem"
        case .any:                 return "Any"
        @unknown default:          return "Unknown(\(type.rawValue))"
        }
    }
}

// MARK: - PaywallLayoutTree schema types

/// Root container for the PaywallLayoutTree JSON output.
/// Conforms to https://revenuecat.com/schemas/paywall-layout-tree.json
///
/// **Coordinate format (extractor 2.4.0+):** all positional values are emitted as
/// integers (rounded via banker's rounding from the raw `CGFloat` snapshot frames).
/// This eliminates sub-pixel layout noise and makes byte-level diffing meaningful.
private struct PaywallLayoutTree: Encodable {

    let metadata: Metadata
    /// Flat dictionary of all identified components, keyed by component ID.
    /// When multiple elements share the same ID, keys are suffixed: "id_0", "id_1", …
    /// All frame coordinates are relative to the paywall root's top-left corner.
    let components: [String: Component]

    /// Rectangle on the device coordinate grid. Integer-valued.
    struct Frame: Encodable {
        let x: Int
        let y: Int
        let width: Int
        let height: Int
    }

    /// Directional inset values (top/bottom/leading/trailing). Integer-valued.
    struct Insets: Encodable {
        let top: Int
        let bottom: Int
        let leading: Int
        let trailing: Int
    }

    struct Metadata: Encodable {
        let platform: String
        let platformVersion: String
        let viewport: Viewport
        /// Frame of the paywall root in screen coordinates.
        /// All component frames are expressed relative to this origin.
        let rootFrame: Frame
        /// Safe-area insets reported by the running app. `nil` for V1 paywalls or
        /// when the safe-area probe could not be read.
        let safeAreaInsets: Insets?
        let offeringId: String
        let locale: String
        /// Free-text label passed by the caller via `DEVICE_CLASS` env var (e.g. "tablet",
        /// "dynamic-island"). Used by downstream cross-platform tooling to correlate
        /// runs without re-parsing the file name.
        let deviceClass: String?
        /// "light" | "dark" — which color scheme the paywall was rendered with.
        let colorScheme: String
        /// "portrait" | "landscape" — orientation at capture time.
        let orientation: String
        let extractorVersion: String
        let timestamp: String

        struct Viewport: Encodable {
            let width: Int
            let height: Int
            /// Physical-pixel scale factor (e.g. 3.0 on Retina iPhones).
            /// Not a coordinate, so kept as Double.
            let scale: Double
        }
    }

    struct Component: Encodable {
        let type: String
        let nativeType: String
        /// The original component ID (before any disambiguation suffix).
        let componentId: String
        let label: String?
        let value: String?
        /// Frame relative to the paywall root's top-left corner. Integer-valued.
        let frame: Frame
        let state: State

        /// Interaction-state flags as reported by XCUITest.
        struct State: Encodable {
            let enabled: Bool
            let selected: Bool
        }
    }
}
