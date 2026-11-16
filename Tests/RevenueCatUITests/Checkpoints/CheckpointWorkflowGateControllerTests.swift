//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointWorkflowGateControllerTests.swift
//

@_spi(Internal) @testable import RevenueCat
@_spi(InviteOnlyCheckpointsApi) @_spi(Internal) @testable import RevenueCatUI
import XCTest

@MainActor
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class CheckpointWorkflowGateControllerTests: TestCase {

    private var controller: CheckpointWorkflowGateController!
    private let hard = CheckpointWorkflowGateControllerTests.step(.hard(entitlementIdentifiers: ["pro", "premium"]))

    override func setUp() {
        super.setUp()
        self.controller = CheckpointWorkflowGateController()
    }

    func testNewControllerHasNoUnresolvedGate() {
        XCTAssertEqual(self.controller.outcome, .notApplicable)
        XCTAssertFalse(self.controller.hasUnresolvedGate)
    }

    func testAnyMatchingCustomerInfoEntitlementPasses() throws {
        _ = try self.update(activeEntitlements: ["premium"])

        XCTAssertEqual(self.controller.evaluate(step: self.hard), .passed)
        _ = self.controller.evaluate(step: self.hard)

        XCTAssertEqual(self.controller.outcome, .passed)
    }

    func testMissingCustomerInfoEntitlementBlocksForwardNavigation() throws {
        _ = try self.update(activeEntitlements: ["unrelated"])

        XCTAssertEqual(self.controller.evaluate(step: self.hard), .blocked)
        XCTAssertTrue(self.controller.blocksForwardNavigation(step: self.hard))
        XCTAssertTrue(self.controller.hasUnresolvedGate)
        XCTAssertEqual(self.controller.outcome, .notPassed)
    }

    func testEnteringAGateDiscardsPreviouslyReadEntitlementsUntilCustomerInfoArrives() throws {
        _ = try self.update(activeEntitlements: ["pro"])

        XCTAssertTrue(self.controller.beginEntry(step: self.hard))
        XCTAssertTrue(self.controller.hasUnresolvedGate)
        XCTAssertTrue(self.controller.blocksForwardNavigation(step: self.hard))
        XCTAssertEqual(try self.update(activeEntitlements: ["premium"]), .passed)
        XCTAssertFalse(self.controller.hasUnresolvedGate)
    }

    func testSoftAndAbsentGatingDoNotBlock() {

        XCTAssertEqual(self.controller.evaluate(step: Self.step(nil)), .notGated)
        XCTAssertEqual(self.controller.evaluate(step: Self.step(.soft)), .notGated)
        XCTAssertFalse(self.controller.blocksForwardNavigation(step: Self.step(nil)))
        XCTAssertFalse(self.controller.blocksForwardNavigation(step: Self.step(.soft)))
        XCTAssertEqual(self.controller.outcome, .notApplicable)
    }

    func testInvalidGatingFailsClosedEvenWithActiveEntitlements() throws {
        _ = try self.update(activeEntitlements: ["pro"])
        let invalid = Self.step(.invalid)

        XCTAssertEqual(self.controller.evaluate(step: invalid), .blocked)
        XCTAssertTrue(self.controller.blocksForwardNavigation(step: invalid))
        XCTAssertEqual(
            try self.update(activeEntitlements: ["pro", "premium"]),
            .blocked
        )
        XCTAssertTrue(self.controller.hasUnresolvedGate)
        XCTAssertEqual(self.controller.outcome, .notPassed)
    }

    func testBacktrackingKeepsUnresolvedOutcomeAndReentryStaysBlocked() {
        _ = self.controller.evaluate(step: self.hard)
        let earlier = Self.step(nil)

        XCTAssertEqual(self.controller.evaluate(step: earlier), .notGated)
        XCTAssertTrue(self.controller.hasUnresolvedGate)
        XCTAssertFalse(self.controller.blocksForwardNavigation(step: earlier))
        XCTAssertEqual(self.controller.evaluate(step: self.hard), .blocked)
        XCTAssertEqual(self.controller.outcome, .notPassed)
    }

    func testCustomerInfoUpdateResolvesAReachedGateEvenWhileBacktracking() throws {
        _ = self.controller.evaluate(step: self.hard)
        _ = self.controller.evaluate(step: Self.step(nil))

        XCTAssertEqual(
            try self.update(activeEntitlements: ["unrelated"]),
            .blocked
        )
        XCTAssertEqual(
            try self.update(activeEntitlements: ["premium"]),
            .passed
        )
        XCTAssertFalse(self.controller.hasUnresolvedGate)
        XCTAssertFalse(self.controller.blocksForwardNavigation(step: self.hard))
        XCTAssertEqual(self.controller.outcome, .passed)
    }

    func testCustomerInfoBeforeReachingAGateUpdatesTheEntryBaseline() throws {

        XCTAssertEqual(
            try self.update(activeEntitlements: ["pro"]),
            .notGated
        )
        XCTAssertEqual(self.controller.evaluate(step: self.hard), .passed)
    }

    func testControllersDoNotShareGateState() throws {
        _ = self.controller.evaluate(step: self.hard)
        _ = try self.update(activeEntitlements: ["pro"])
        let nextController = CheckpointWorkflowGateController()

        XCTAssertEqual(nextController.outcome, .notApplicable)
        XCTAssertFalse(nextController.hasUnresolvedGate)
        XCTAssertEqual(nextController.evaluate(step: self.hard), .blocked)
        XCTAssertEqual(self.controller.outcome, .passed)
    }

    private func update(activeEntitlements: [String]) throws -> WorkflowGateDecision {
        return self.controller.update(
            customerInfo: try CheckpointTestFixtures.customerInfo(activeEntitlements: activeEntitlements)
        )
    }

    private static func step(_ gating: WorkflowStepGating?) -> WorkflowStep {
        var step = WorkflowStep(
            id: gating == nil ? "earlier" : "gated",
            type: "screen",
            screenId: "screen"
        )
        switch gating {
        case let .hard(identifiers):
            step.paramValues["gating"] = .object([
                "type": .string("hard"),
                "entitlement_identifiers": .array(identifiers.sorted().map(AnyDecodable.string))
            ])
        case .soft:
            step.paramValues["gating"] = .object(["type": .string("soft")])
        case .invalid:
            step.paramValues["gating"] = .null
        case nil:
            break
        }
        return step
    }

}
