/*
 PaywallAccessibilityTreeTests
 ==============================
 Captures the XCUITest accessibility tree of a rendered paywall and exports it
 as a structured JSON file conforming to the PaywallLayoutTree schema.

 OUTPUT FORMAT
 -------------
 The JSON contains a flat `components` dictionary keyed by component ID
 (the accessibility identifier set on each rendered element). All frame
 coordinates are in the coordinate system of the paywall root — i.e.
 (0, 0) is the top-left corner of the paywall content area.

 When the same component ID appears on multiple elements (unusual but possible),
 the entries are disambiguated with a numeric suffix: "id_0", "id_1", …

 Only elements that carry a non-empty accessibility identifier are included.

 This test target is attached to the PaywallsTester app. It can navigate via two paths:

 A) Examples tab (no API key required) — opens the first V1 template paywall.
 B) Live Paywalls tab (API key required) — loads a specific offering by ID from
    the RevenueCat backend and opens its paywall.

 HOW TO RUN
 ----------

 Examples tab (default, no API key):

      xcodebuild test \
        -workspace Tests/TestingApps/PaywallsTester/PaywallsTester.xcworkspace \
        -scheme "PaywallAccessibilityTreeTests" \
        -destination 'platform=iOS Simulator,name=iPhone 17' \
        -only-testing PaywallsTesterUITests/PaywallAccessibilityTreeTests/testCaptureAccessibilityTree

 Live Paywalls tab (V2 paywall by offering ID):

      TEST_RUNNER_RC_API_KEY=appl_xxx TEST_RUNNER_OFFERING_ID=my-v2-offering xcodebuild test \
        -workspace Tests/TestingApps/PaywallsTester/PaywallsTester.xcworkspace \
        -scheme "PaywallAccessibilityTreeTests" \
        -destination 'platform=iOS Simulator,name=iPhone 17' \
        -only-testing PaywallsTesterUITests/PaywallAccessibilityTreeTests/testCaptureAccessibilityTree

   RC_API_KEY  — RevenueCat API key; triggers the Live Paywalls navigation path.
   OFFERING_ID — offering to open; required when RC_API_KEY is set.
                 When omitted without RC_API_KEY, defaults to "examples-first".

 OUTPUT
 ------
 JSON file written to /tmp/ (and ~/Desktop/ when the host home directory is discoverable):
   paywall-tree-<offering-id>-<timestamp>.json

 The JSON conforms to the PaywallLayoutTree schema at:
   https://revenuecat.com/schemas/paywall-layout-tree.json
*/

import XCTest

final class PaywallAccessibilityTreeTests: XCTestCase {

    private static let appLaunchTimeout: TimeInterval = 20
    private static let paywallLoadTimeout: TimeInterval = 15
    private static let offeringsLoadTimeout: TimeInterval = 30

    // MARK: - Schema version

    private static let extractorVersion = "2.0.0"

    // MARK: - Test

    func testCaptureAccessibilityTree() throws {
        let paywallId = ProcessInfo.processInfo.environment["OFFERING_ID"] ?? "examples-first"
        let apiKey = ProcessInfo.processInfo.environment["RC_API_KEY"]

        let app = XCUIApplication()
        if let apiKey = apiKey {
            app.launchEnvironment["REVENUECAT_API_KEY"] = apiKey
            app.launchEnvironment["OFFERING_ID"] = paywallId
        }
        app.launch()

        if apiKey != nil {
            try navigateToLivePaywall(in: app, id: paywallId)
        } else {
            try navigateToExamplesPaywall(in: app, id: paywallId)
        }

        // Let SwiftUI layout settle
        Thread.sleep(forTimeInterval: 2)

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

        // Build metadata
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        let platformVersion = "\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
        let appFrame = appSnapshot.frame
        let rootCGFrame = paywallSnapshot.frame

        let metadata = PaywallLayoutTree.Metadata(
            platform: "ios",
            platformVersion: platformVersion,
            viewport: PaywallLayoutTree.Metadata.Viewport(
                width: Double(appFrame.width),
                height: Double(appFrame.height),
                scale: screenScale()
            ),
            rootFrame: PaywallLayoutTree.Metadata.Frame(
                x: Double(rootCGFrame.origin.x),
                y: Double(rootCGFrame.origin.y),
                width: Double(rootCGFrame.size.width),
                height: Double(rootCGFrame.size.height)
            ),
            offeringId: paywallId,
            locale: Locale.current.identifier,
            extractorVersion: Self.extractorVersion,
            timestamp: ISO8601DateFormatter().string(from: Date())
        )

        let tree = PaywallLayoutTree(metadata: metadata, components: components)

        // Encode to JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let jsonData = try encoder.encode(tree)

        // Build filename
        let safe = paywallId
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let filename = "paywall-tree-\(safe)-\(timestamp).json"

        // Write to /tmp/ (accessible from both simulator and host)
        let tmpURL = URL(fileURLWithPath: "/tmp").appendingPathComponent(filename)
        try jsonData.write(to: tmpURL)

        // Attempt host Desktop copy when the host home is discoverable
        let hostHomeEnv = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"]
            ?? ProcessInfo.processInfo.environment["HOME"]
        if let hostHome = hostHomeEnv, !hostHome.contains("CoreSimulator") {
            let desktopURL = URL(fileURLWithPath: hostHome)
                .appendingPathComponent("Desktop")
                .appendingPathComponent(filename)
            try? jsonData.write(to: desktopURL)
            print("  Desktop copy: \(desktopURL.path)")
        }

        // Always attach to the .xcresult bundle — extractable via `xcrun xcresulttool`
        let attachment = XCTAttachment(data: jsonData, uniformTypeIdentifier: "public.json")
        attachment.name = filename
        attachment.lifetime = XCTAttachment.Lifetime.keepAlways
        add(attachment)

        print("────────────────────────────────────────")
        print("Accessibility tree written to:")
        print("  /tmp/\(filename)")
        print("────────────────────────────────────────")
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
            Thread.sleep(forTimeInterval: 2)
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

        // Let layout and animations settle.
        Thread.sleep(forTimeInterval: 2)
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

        Thread.sleep(forTimeInterval: 2)
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

        // Assign dictionary keys, adding numeric suffixes for duplicates.
        var idIndices: [String: Int] = [:]
        var result: [String: PaywallLayoutTree.Component] = [:]

        for (id, snapshot) in pairs {
            let key: String
            if idCounts[id]! > 1 {
                let idx = idIndices[id, default: 0]
                key = "\(id)_\(idx)"
                idIndices[id] = idx + 1
            } else {
                key = id
            }

            let cgFrame = snapshot.frame
            let frame = PaywallLayoutTree.Component.Frame(
                x: Double(cgFrame.origin.x - origin.x),
                y: Double(cgFrame.origin.y - origin.y),
                width: Double(cgFrame.size.width),
                height: Double(cgFrame.size.height)
            )

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
    private func collectIdedSnapshots(
        _ snapshot: any XCUIElementSnapshot,
        into pairs: inout [(id: String, snapshot: any XCUIElementSnapshot)]
    ) {
        if !snapshot.identifier.isEmpty {
            pairs.append((snapshot.identifier, snapshot))
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
private struct PaywallLayoutTree: Encodable {

    let metadata: Metadata
    /// Flat dictionary of all identified components, keyed by component ID.
    /// When multiple elements share the same ID, keys are suffixed: "id_0", "id_1", …
    /// All frame coordinates are relative to the paywall root's top-left corner.
    let components: [String: Component]

    struct Metadata: Encodable {
        let platform: String
        let platformVersion: String
        let viewport: Viewport
        /// Frame of the paywall root in screen coordinates.
        /// All component frames are expressed relative to this origin.
        let rootFrame: Frame
        let offeringId: String
        let locale: String
        let extractorVersion: String
        let timestamp: String

        struct Viewport: Encodable {
            let width: Double
            let height: Double
            let scale: Double
        }

        struct Frame: Encodable {
            let x: Double
            let y: Double
            let width: Double
            let height: Double
        }
    }

    struct Component: Encodable {
        let type: String
        let nativeType: String
        /// The original component ID (before any disambiguation suffix).
        let componentId: String
        let label: String?
        let value: String?
        /// Frame relative to the paywall root's top-left corner.
        let frame: Frame
        let state: State

        struct Frame: Encodable {
            let x: Double
            let y: Double
            let width: Double
            let height: Double
        }

        /// Interaction-state flags as reported by XCUITest.
        struct State: Encodable {
            let enabled: Bool
            let selected: Bool
        }
    }
}
