//
//  Copyright RevenueCat Inc. All Rights Reserved.
//

import XCTest

final class NativeAnalyticsUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }

    func testNativeAndEmbeddedCloseHaveMatchingAnalytics() throws {
        try self.assertParity(rootBack: false, navigateDeeper: false)
    }

    func testRootBackDisplayedAsNativeCloseMatchesEmbeddedBackAnalytics() throws {
        try self.assertParity(rootBack: true, navigateDeeper: false)
    }

    func testNativeAndEmbeddedBackHaveMatchingAnalyticsAfterNavigation() throws {
        try self.assertParity(rootBack: false, navigateDeeper: true)
    }

    private func assertParity(rootBack: Bool, navigateDeeper: Bool) throws {
        let embedded = try self.record(native: false, rootBack: rootBack, navigateDeeper: navigateDeeper)
        let native = try self.record(native: true, rootBack: rootBack, navigateDeeper: navigateDeeper)
        XCTAssertEqual(embedded as NSDictionary, native as NSDictionary)
    }

    private func record(native: Bool, rootBack: Bool, navigateDeeper: Bool) throws -> [String: Any] {
        let app = XCUIApplication()
        app.launchEnvironment["PAYWALL_FIXTURE"] = "native_workflow_navigation"
        app.launchEnvironment["PAYWALL_ANALYTICS"] = native ? "native" : "embedded"
        app.launchEnvironment["PAYWALL_ANALYTICS_ROOT_BACK"] = rootBack ? "true" : "false"
        app.launch()
        defer { app.terminate() }
        self.waitFor(app.staticTexts["Workflow root"])
        if navigateDeeper {
            app.buttons["Continue"].tap()
            self.waitFor(app.staticTexts["Workflow detail"])
        }
        let isBack = rootBack || navigateDeeper
        let button = app.buttons[native
            ? (navigateDeeper ? "RevenueCat.NativePaywallBack" : "RevenueCat.NativePaywallClose")
            : (isBack ? "Designed Back" : "Designed Close")]
        self.waitFor(button)
        button.tap()
        self.waitFor(app.staticTexts[navigateDeeper ? "Workflow root" : "Paywall dismissed"])
        XCTAssertEqual(app.staticTexts["Paywall dismissed"].exists, !navigateDeeper)
        app.buttons["Capture analytics"].tap()
        let result = app.staticTexts["analytics-result"]
        let captured = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (result.value as? String)?.hasPrefix("{") == true
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [captured], timeout: 10), .completed, app.debugDescription)
        let json = try XCTUnwrap(result.value as? String)
        let report = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        return try self.validateAndNormalize(report, isBack: isBack, navigateDeeper: navigateDeeper)
    }

    /// Compare every payload field, excluding generated trace/session IDs after validating their relationships.
    /// Paywall events are compared in visit order; only ordering within each visit is required.
    private func validateAndNormalize(
        _ report: [String: Any], isBack: Bool, navigateDeeper: Bool
    ) throws -> [String: Any] {
        let paywall = try XCTUnwrap(report["paywall"] as? [[String: Any]])
        var workflow = try XCTUnwrap(report["workflow"] as? [[String: Any]])
        let firstWorkflowData = try XCTUnwrap(workflow.first?["data"] as? [String: Any])
        let trace = try XCTUnwrap(firstWorkflowData["traceId"] as? String)
        XCTAssertFalse(trace.isEmpty)
        let impressions = paywall.filter { $0["kind"] as? String == "impression" }
        XCTAssertEqual(impressions.count, navigateDeeper ? 3 : 1)
        let impressionData = try impressions.map { try XCTUnwrap($0["data"] as? [String: Any]) }
        let sessions = try impressionData.map { try XCTUnwrap($0["sessionIdentifier"] as? String) }
        XCTAssertEqual(Set(sessions).count, sessions.count, "Returning to root must start a new visit")
        XCTAssertEqual(impressionData.compactMap { $0["stepId"] as? String },
                       navigateDeeper ? ["root", "detail", "root"] : ["root"])
        let interactions = paywall.filter { $0["kind"] as? String == "interaction" }
        XCTAssertEqual(interactions.count, 1)
        let interaction = try XCTUnwrap(interactions.first?["interaction"] as? [String: Any])
        XCTAssertEqual(interaction["componentType"] as? String, "button")
        XCTAssertEqual(interaction["componentName"] as? String, isBack ? "Designed Back" : "Designed Close")
        XCTAssertEqual(interaction["componentValue"] as? String, isBack ? "navigate_back" : "close_workflow")
        let interactionData = try XCTUnwrap(interactions.first?["data"] as? [String: Any])
        XCTAssertEqual(interactionData["stepId"] as? String, navigateDeeper ? "detail" : "root")
        XCTAssertEqual(paywall.filter { $0["kind"] as? String == "close" }.count, navigateDeeper ? 0 : 1)

        var visits = Array(repeating: [[String: Any]](), count: sessions.count)
        for var event in paywall {
            var data = try XCTUnwrap(event["data"] as? [String: Any])
            let session = try XCTUnwrap(data["sessionIdentifier"] as? String)
            let visit = try XCTUnwrap(sessions.firstIndex(of: session), "Event attributed to an unknown session")
            XCTAssertEqual(data as NSDictionary, impressionData[visit] as NSDictionary)
            XCTAssertEqual(data["traceId"] as? String, trace)
            XCTAssertEqual(data["workflowId"] as? String, "native-navigation-fixture")
            XCTAssertEqual(data["paywallIdentifier"] as? String, data["stepId"] as? String)
            data["traceId"] = "trace"
            data["sessionIdentifier"] = "visit-\(visit)"
            event["data"] = data
            visits[visit].append(event)
        }
        let expectedVisits = navigateDeeper
            ? [["impression"], ["impression", "interaction"], ["impression"]]
            : [["impression", "interaction", "close"]]
        XCTAssertEqual(visits.map { $0.compactMap { $0["kind"] as? String } }, expectedVisits)

        XCTAssertEqual(workflow.compactMap { $0["kind"] as? String }, navigateDeeper
            ? ["started", "completed", "started", "completed", "started"]
            : ["started", "completed", "close"])
        if navigateDeeper {
            let completion = try XCTUnwrap(workflow.dropFirst(3).first?["data"] as? [String: Any])
            let reentry = try XCTUnwrap(workflow.dropFirst(4).first?["data"] as? [String: Any])
            XCTAssertEqual(completion["toStepId"] as? String, "root")
            XCTAssertEqual(reentry["entryReason"] as? String, "back")
            XCTAssertEqual(reentry["fromStepId"] as? String, "detail")
        }
        for index in workflow.indices {
            var data = try XCTUnwrap(workflow[index]["data"] as? [String: Any])
            XCTAssertEqual(data["traceId"] as? String, trace)
            XCTAssertEqual(data["workflowId"] as? String, "native-navigation-fixture")
            data["traceId"] = "trace"
            workflow[index]["data"] = data
        }
        return ["paywallVisits": visits, "workflow": workflow]
    }

    private func waitFor(_ element: XCUIElement) {
        let visible = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == true AND hittable == true"), object: element
        )
        XCTAssertEqual(XCTWaiter.wait(for: [visible], timeout: 15), .completed, element.debugDescription)
    }
}
