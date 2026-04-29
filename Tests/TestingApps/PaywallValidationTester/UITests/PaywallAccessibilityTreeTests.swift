/*
 PaywallAccessibilityTreeTests
 ==============================
 Captures the raw XCUITest accessibility tree of a rendered paywall and writes it
 to a human-readable text file on the host Desktop.

 HOW TO RUN
 ----------
 1. Generate the Tuist workspace (one-time, or after editing Project.swift):

      tuist generate PaywallValidationTester

 2. Run the test, passing an offering ID via the TEST_RUNNER_ prefix:

      TEST_RUNNER_OFFERING_ID=template_001 xcodebuild test \
        -workspace RevenueCat-Tuist.xcworkspace \
        -scheme "PaywallValidationTesterUITests" \
        -destination 'platform=iOS Simulator,name=iPhone 17' \
        -only-testing PaywallValidationTesterUITests/PaywallAccessibilityTreeTests/testCaptureAccessibilityTree

      The TEST_RUNNER_ prefix causes xcodebuild to strip the prefix and pass
      OFFERING_ID directly into the test runner process environment, where the
      test reads it via ProcessInfo.processInfo.environment["OFFERING_ID"].

 3. Find the output file on the host Desktop:

      ~/Desktop/paywall-tree-<offering-id>-<timestamp>.txt

 NOTES
 -----
 - If OFFERING_ID is omitted, the app shows all available offerings scrolled
   horizontally. The dump will capture all visible content; the filename will
   use "all" for the ID portion.
 - The paywall-preview-resources folder must be populated before running.
   Run `bundle exec fastlane fetch_paywall_preview_resources` (or
   `git clone git@github.com:RevenueCat/paywall-preview-resources.git Tests/paywall-preview-resources`)
   and check out the commit hash in Tests/paywall-preview-resources-commit.
 - The output is intentionally raw and unprocessed — no normalization, no schema
   mapping — so the completeness of XCUITest's accessibility tree can be evaluated.
*/

import XCTest

final class PaywallAccessibilityTreeTests: XCTestCase {

    private static let waitTimeout: TimeInterval = 20

    func testCaptureAccessibilityTree() throws {
        let offeringId = ProcessInfo.processInfo.environment["OFFERING_ID"] ?? "all"

        let app = XCUIApplication()
        if offeringId != "all" {
            app.launchEnvironment["OFFERING_ID"] = offeringId
        }
        app.launch()

        // Wait for paywall content to start rendering (local JSON, no network needed)
        let firstText = app.staticTexts.firstMatch
        let appeared = firstText.waitForExistence(timeout: Self.waitTimeout)
        if !appeared {
            // Fall back to a blind sleep if no static text appears yet (image-heavy paywall)
            Thread.sleep(forTimeInterval: 4)
        } else {
            // Extra settle time for animations and lazy layout passes
            Thread.sleep(forTimeInterval: 2)
        }

        let snapshot = try app.snapshot()
        let dump = buildDump(snapshot, depth: 0)

        let header = """
        PaywallAccessibilityTreeDump
        OfferingId : \(offeringId)
        CapturedAt : \(ISO8601DateFormatter().string(from: Date()))
        DeviceName : \(UIDevice.current.name)
        OSVersion  : \(UIDevice.current.systemVersion)
        ScreenSize : \(UIScreen.main.bounds.size)
        ────────────────────────────────────────────────────────────────────────────

        """

        let output = header + dump

        let safe = offeringId.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: " ", with: "_")
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let filename = "paywall-tree-\(safe)-\(timestamp).txt"

        // In Xcode 26 UITests the runner executes inside the iOS simulator, so
        // NSHomeDirectory() returns the app container. Write to /tmp/ which is
        // accessible from both the simulator and the host machine.
        let tmpURL = URL(fileURLWithPath: "/tmp").appendingPathComponent(filename)
        try output.write(to: tmpURL, atomically: true, encoding: .utf8)

        let hostHomeEnv = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"]
            ?? ProcessInfo.processInfo.environment["HOME"]
        if let hostHome = hostHomeEnv, !hostHome.contains("CoreSimulator") {
            let desktopURL = URL(fileURLWithPath: hostHome)
                .appendingPathComponent("Desktop")
                .appendingPathComponent(filename)
            try? output.write(to: desktopURL, atomically: true, encoding: .utf8)
        }

        let attachment = XCTAttachment(string: output)
        attachment.name = filename
        attachment.lifetime = .keepAlways
        add(attachment)

        print("────────────────────────────────────────────")
        print("Accessibility tree written to: /tmp/\(filename)")
        print("────────────────────────────────────────────")
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
