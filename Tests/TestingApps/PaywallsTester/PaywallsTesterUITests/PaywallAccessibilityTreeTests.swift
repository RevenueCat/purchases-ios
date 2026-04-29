/*
 PaywallAccessibilityTreeTests
 ==============================
 Captures the raw XCUITest accessibility tree of a rendered paywall and writes it
 to a human-readable text file on the host Desktop.

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
 File is written to the host Desktop:
   ~/Desktop/paywall-tree-<offering-id>-<timestamp>.txt

 The dump is intentionally raw — no normalization, no schema mapping — so the
 completeness of the XCUITest accessibility tree can be evaluated before
 investing in a data model.
*/

import XCTest

final class PaywallAccessibilityTreeTests: XCTestCase {

    private static let appLaunchTimeout: TimeInterval = 20
    private static let paywallLoadTimeout: TimeInterval = 15
    private static let offeringsLoadTimeout: TimeInterval = 30

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

        // Capture the full accessibility snapshot
        let snapshot = try app.snapshot()
        let dump = buildDump(snapshot, depth: 0)

        // Write header + tree to Desktop on the host machine
        let header = """
        PaywallAccessibilityTreeDump
        OfferingId : \(paywallId)
        CapturedAt : \(ISO8601DateFormatter().string(from: Date()))
        ────────────────────────────────────────────────────────────────────────────

        """

        let output = header + dump

        let safe = paywallId
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let filename = "paywall-tree-\(safe)-\(timestamp).txt"

        // In Xcode 26 UITests the runner process executes inside the iOS simulator,
        // so NSHomeDirectory() returns the app container, not the host Desktop.
        // We write to /tmp/ which is accessible from both the simulator and the host.
        // If SIMULATOR_HOST_HOME is set (injected by the test environment) we also
        // write a copy to ~/Desktop/ on the host.
        let tmpURL = URL(fileURLWithPath: "/tmp").appendingPathComponent(filename)
        try output.write(to: tmpURL, atomically: true, encoding: .utf8)

        // Attempt host Desktop copy when the host home is discoverable
        let hostHomeEnv = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"]
            ?? ProcessInfo.processInfo.environment["HOME"]
        if let hostHome = hostHomeEnv, !hostHome.contains("CoreSimulator") {
            let desktopURL = URL(fileURLWithPath: hostHome)
                .appendingPathComponent("Desktop")
                .appendingPathComponent(filename)
            try? output.write(to: desktopURL, atomically: true, encoding: .utf8)
            print("  Desktop copy: \(desktopURL.path)")
        }

        // Always attach to the .xcresult bundle — extractable via `xcrun xcresulttool`
        let attachment = XCTAttachment(string: output)
        attachment.name = filename
        attachment.lifetime = .keepAlways
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

    // MARK: - Tree walker

    private func buildDump(_ node: any XCUIElementSnapshot, depth: Int) -> String {
        let indent = String(repeating: "  ", count: depth)
        var parts: [String] = []

        let typeStr = elementTypeName(node.elementType)
        parts.append(typeStr)

        let id = node.identifier
        parts.append("id=\(id.isEmpty ? "(none)" : "\"\(id)\"")")

        let label = node.label
        parts.append("label=\(label.isEmpty ? "(none)" : "\"\(label)\"")")

        if let value = node.value {
            let valueStr = "\(value)"
            parts.append("value=\(valueStr.isEmpty ? "(empty)" : "\"\(valueStr)\"")")
        }

        let title = node.title
        if !title.isEmpty {
            parts.append("title=\"\(title)\"")
        }

        let frame = node.frame
        parts.append(String(
            format: "frame={{%.0f,%.0f},{%.0f,%.0f}}",
            frame.origin.x, frame.origin.y,
            frame.size.width, frame.size.height
        ))

        var flags: [String] = []
        if !node.isEnabled { flags.append("disabled") }
        if node.isSelected { flags.append("selected") }
        if !flags.isEmpty { parts.append("[\(flags.joined(separator: ","))]") }

        var lines = [indent + parts.joined(separator: "  ")]
        for child in node.children {
            lines.append(buildDump(child, depth: depth + 1))
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Element type name

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
        @unknown default:          return "Unknown(\(type.rawValue))"
        }
    }
}
