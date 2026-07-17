//
//  PaywallsTesterTests.swift
//  PaywallsTesterTests
//
//  Created by Noah Martin on 10/24/24.
//

import SnapshottingTests
@testable import PaywallsTester
import XCTest

final class PaywallsTesterTests: SnapshotTest {
    override class func snapshotPreviews() -> [String]? {
        // Gets around an issue that was causing StoreKit previews to be included when running in Catalyst mode.
        // Should be fixed in EmergeTools v0.10.23+, and this won't be necessary anymore.
        // This method only applies when running these tests locally. When running on EmergeTools' server,
        // we apply the same exclusion by specifying it in emerge_config.yaml.
        // PR: https://github.com/EmergeTools/SnapshotPreviews/pull/239
        return ["PaywallsTester.*", "RevenueCatUI.*"]
    }
}

final class PaywallSectionTests: XCTestCase {

    func testNoPaywallTakesPrecedenceOverLegacyTemplateName() {
        let section = APIKeyDashboardList.PaywallSection(
            hasPaywall: false,
            legacyTemplateName: "1"
        )

        XCTAssertEqual(section, .noPaywall)
        XCTAssertEqual(section.description, "No paywall")
    }

    func testClassicPaywallUsesLegacyTemplateSection() {
        let section = APIKeyDashboardList.PaywallSection(
            hasPaywall: true,
            legacyTemplateName: "1"
        )

        XCTAssertEqual(section, .legacy(templateName: "1"))
        XCTAssertEqual(section.description, "1: Minimalist")
    }

    func testRetainedV2PaywallUsesComponentsSection() {
        let section = APIKeyDashboardList.PaywallSection(
            hasPaywall: true,
            legacyTemplateName: nil
        )

        XCTAssertEqual(section, .components)
        XCTAssertEqual(section.description, "V2")
    }

    func testPrunedWorkflowPaywallUsesComponentsSection() {
        let section = APIKeyDashboardList.PaywallSection(
            hasPaywall: true,
            legacyTemplateName: nil
        )

        XCTAssertEqual(section, .components)
    }

    func testNoPaywallSectionSortsLast() {
        let sections: [APIKeyDashboardList.PaywallSection] = [
            .noPaywall,
            .components,
            .legacy(templateName: "1")
        ]

        XCTAssertEqual(
            sections.sorted(),
            [.legacy(templateName: "1"), .components, .noPaywall]
        )
    }

}
