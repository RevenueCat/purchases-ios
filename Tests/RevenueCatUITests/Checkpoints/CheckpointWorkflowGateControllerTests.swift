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
        XCTAssertEqual(self.controller.status, .notApplicable)
        XCTAssertFalse(self.controller.hasUnresolvedGate)
    }

    func testPendingBranchStaysUnresolvedAfterCustomerInfoArrives() throws {
        self.controller.markInitialBranchPending()

        XCTAssertEqual(try self.update(activeEntitlements: ["pro"]), .notGated)
        XCTAssertEqual(self.controller.status, .notPassed)
        XCTAssertTrue(self.controller.hasUnresolvedGate)
    }

    func testUngatedEntryClearsPendingBranch() {
        for gating: WorkflowStepGating? in [nil, .soft] {
            self.controller.markInitialBranchPending()

            XCTAssertFalse(self.controller.beginEntry(step: Self.step(gating)))
            XCTAssertEqual(self.controller.status, .notApplicable)
            XCTAssertFalse(self.controller.hasUnresolvedGate)
        }
    }

    func testHardGateEntryReplacesPendingBranch() throws {
        self.controller.markInitialBranchPending()

        XCTAssertTrue(self.controller.beginEntry(step: self.hard))
        XCTAssertEqual(self.controller.status, .notPassed)
        XCTAssertEqual(try self.update(activeEntitlements: ["pro"]), .passed)
        XCTAssertEqual(self.controller.status, .passed)
    }

    func testUngatedEntryPreservesReachedGateAndTracksEntitlementLoss() throws {
        _ = self.controller.beginEntry(step: self.hard)
        _ = try self.update(activeEntitlements: ["pro"])

        XCTAssertFalse(self.controller.beginEntry(step: Self.step(nil)))
        XCTAssertEqual(self.controller.status, .passed)
        XCTAssertEqual(try self.update(activeEntitlements: []), .blocked)
        XCTAssertEqual(self.controller.status, .notPassed)
        XCTAssertTrue(self.controller.hasUnresolvedGate)
    }

    func testAnyMatchingCustomerInfoEntitlementPasses() throws {
        XCTAssertTrue(self.controller.beginEntry(step: self.hard))

        XCTAssertEqual(try self.update(activeEntitlements: ["premium"]), .passed)
        XCTAssertEqual(self.controller.status, .passed)
        XCTAssertFalse(self.controller.blocksForwardNavigation(step: self.hard))
    }

    func testMissingCustomerInfoEntitlementBlocksForwardNavigation() throws {
        XCTAssertTrue(self.controller.beginEntry(step: self.hard))

        XCTAssertEqual(try self.update(activeEntitlements: ["unrelated"]), .blocked)
        XCTAssertTrue(self.controller.blocksForwardNavigation(step: self.hard))
        XCTAssertTrue(self.controller.hasUnresolvedGate)
        XCTAssertEqual(self.controller.status, .notPassed)
    }

    func testEnteringAGateDiscardsPreviouslyReadEntitlementsUntilCustomerInfoArrives() throws {
        XCTAssertEqual(try self.update(activeEntitlements: ["pro"]), .notGated)
        XCTAssertEqual(self.controller.status, .notApplicable)

        XCTAssertTrue(self.controller.beginEntry(step: self.hard))
        XCTAssertEqual(self.controller.status, .notPassed)
        XCTAssertTrue(self.controller.hasUnresolvedGate)
        XCTAssertTrue(self.controller.blocksForwardNavigation(step: self.hard))
        XCTAssertEqual(try self.update(activeEntitlements: ["premium"]), .passed)
        XCTAssertEqual(self.controller.status, .passed)
        XCTAssertFalse(self.controller.hasUnresolvedGate)
    }

    func testSoftAndAbsentGatingDoNotBlock() {

        XCTAssertFalse(self.controller.beginEntry(step: Self.step(nil)))
        XCTAssertFalse(self.controller.beginEntry(step: Self.step(.soft)))
        XCTAssertFalse(self.controller.blocksForwardNavigation(step: Self.step(nil)))
        XCTAssertFalse(self.controller.blocksForwardNavigation(step: Self.step(.soft)))
        XCTAssertEqual(self.controller.status, .notApplicable)
    }

    func testInvalidGatingFailsClosedEvenWithActiveEntitlements() throws {
        let invalid = Self.step(.invalid)

        XCTAssertTrue(self.controller.beginEntry(step: invalid))
        XCTAssertEqual(
            try self.update(activeEntitlements: ["pro", "premium"]),
            .blocked
        )
        XCTAssertTrue(self.controller.blocksForwardNavigation(step: invalid))
        XCTAssertTrue(self.controller.hasUnresolvedGate)
        XCTAssertEqual(self.controller.status, .notPassed)
    }

    func testBacktrackingKeepsUnresolvedStatusAndReentryStaysBlocked() {
        XCTAssertTrue(self.controller.beginEntry(step: self.hard))
        let earlier = Self.step(nil)

        XCTAssertFalse(self.controller.beginEntry(step: earlier))
        XCTAssertTrue(self.controller.hasUnresolvedGate)
        XCTAssertFalse(self.controller.blocksForwardNavigation(step: earlier))
        XCTAssertTrue(self.controller.beginEntry(step: self.hard))
        XCTAssertEqual(self.controller.status, .notPassed)
    }

    func testCustomerInfoUpdateResolvesAReachedGateEvenWhileBacktracking() throws {
        XCTAssertTrue(self.controller.beginEntry(step: self.hard))
        XCTAssertFalse(self.controller.beginEntry(step: Self.step(nil)))

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
        XCTAssertEqual(self.controller.status, .passed)
    }

    func testControllersDoNotShareGateState() throws {
        XCTAssertTrue(self.controller.beginEntry(step: self.hard))
        _ = try self.update(activeEntitlements: ["pro"])
        let nextController = CheckpointWorkflowGateController()

        XCTAssertEqual(nextController.status, .notApplicable)
        XCTAssertFalse(nextController.hasUnresolvedGate)
        XCTAssertTrue(nextController.beginEntry(step: self.hard))
        XCTAssertEqual(nextController.status, .notPassed)
        XCTAssertEqual(self.controller.status, .passed)
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
