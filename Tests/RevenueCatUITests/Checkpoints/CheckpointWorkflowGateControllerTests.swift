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

    private var outcomes: [CheckpointGateOutcome] = []
    private var appUserID = "customer-a"
    private var controller: CheckpointWorkflowGateController!
    private let hard = CheckpointWorkflowGateControllerTests.step(.hard(entitlementIdentifiers: ["pro", "premium"]))

    override func setUp() {
        super.setUp()
        self.controller = CheckpointWorkflowGateController(currentAppUserID: { [unowned self] in self.appUserID })
    }

    func testHardGateWithoutCheckpointContextIsDisabled() {
        self.controller.reset(context: nil)

        XCTAssertEqual(self.controller.evaluate(step: self.hard), .notGated)
        XCTAssertFalse(self.controller.blocksForwardNavigation(step: self.hard))
    }

    func testAnyInitialMatchingEntitlementPassesAndReportsOnce() {
        self.reset(activeEntitlements: ["premium"])

        XCTAssertEqual(self.controller.evaluate(step: self.hard), .passed)
        _ = self.controller.evaluate(step: self.hard)

        XCTAssertEqual(self.outcomes, [.notApplicable, .passed])
    }

    func testMissingInitialEntitlementBlocksForwardNavigation() {
        self.reset(activeEntitlements: ["unrelated"])

        XCTAssertEqual(self.controller.evaluate(step: self.hard), .blocked)
        XCTAssertTrue(self.controller.blocksForwardNavigation(step: self.hard))
        XCTAssertTrue(self.controller.hasUnresolvedGate)
        XCTAssertEqual(self.outcomes, [.notApplicable, .notPassed])
    }

    func testSoftAndAbsentGatingDoNotBlock() {
        self.reset(activeEntitlements: [])

        XCTAssertEqual(self.controller.evaluate(step: Self.step(nil)), .notGated)
        XCTAssertEqual(self.controller.evaluate(step: Self.step(.soft)), .notGated)
        XCTAssertFalse(self.controller.blocksForwardNavigation(step: Self.step(nil)))
        XCTAssertFalse(self.controller.blocksForwardNavigation(step: Self.step(.soft)))
        XCTAssertEqual(self.outcomes, [.notApplicable])
    }

    func testInvalidGatingFailsClosedEvenWithActiveEntitlements() throws {
        self.reset(activeEntitlements: ["pro"])
        let invalid = Self.step(.invalid)

        XCTAssertEqual(self.controller.evaluate(step: invalid), .blocked)
        XCTAssertTrue(self.controller.blocksForwardNavigation(step: invalid))
        XCTAssertEqual(
            try self.update(for: self.appUserID, activeEntitlements: ["pro", "premium"]),
            .blocked
        )
        XCTAssertTrue(self.controller.hasUnresolvedGate)
        XCTAssertEqual(self.outcomes, [.notApplicable, .notPassed])
    }

    func testBacktrackingKeepsUnresolvedOutcomeAndReentryStaysBlocked() {
        self.reset(activeEntitlements: [])
        _ = self.controller.evaluate(step: self.hard)
        let earlier = Self.step(nil)

        XCTAssertEqual(self.controller.evaluate(step: earlier), .notGated)
        XCTAssertTrue(self.controller.hasUnresolvedGate)
        XCTAssertFalse(self.controller.blocksForwardNavigation(step: earlier))
        XCTAssertEqual(self.controller.evaluate(step: self.hard), .blocked)
        XCTAssertEqual(self.outcomes, [.notApplicable, .notPassed])
    }

    func testCustomerInfoUpdateResolvesAReachedGateEvenWhileBacktracking() throws {
        self.reset(activeEntitlements: [])
        _ = self.controller.evaluate(step: self.hard)
        _ = self.controller.evaluate(step: Self.step(nil))

        XCTAssertEqual(
            try self.update(for: self.appUserID, activeEntitlements: ["unrelated"]),
            .blocked
        )
        XCTAssertEqual(
            try self.update(for: self.appUserID, activeEntitlements: ["premium"]),
            .passed
        )
        XCTAssertFalse(self.controller.hasUnresolvedGate)
        XCTAssertFalse(self.controller.blocksForwardNavigation(step: self.hard))
        XCTAssertEqual(self.outcomes, [.notApplicable, .notPassed, .passed])
    }

    func testCustomerInfoBeforeReachingAGateUpdatesTheEntryBaseline() throws {
        self.reset(activeEntitlements: [])

        XCTAssertEqual(
            try self.update(for: self.appUserID, activeEntitlements: ["pro"]),
            .notGated
        )
        XCTAssertEqual(self.controller.evaluate(step: self.hard), .passed)
    }

    func testIdentityChangeInvalidatesInitialEntitlementsAndKeepsBacktrackedGateUnresolved() throws {
        self.reset(activeEntitlements: ["pro"])
        self.appUserID = "customer-b"

        XCTAssertEqual(self.controller.evaluate(step: self.hard), .blocked)
        _ = self.controller.evaluate(step: Self.step(nil))
        XCTAssertTrue(self.controller.hasUnresolvedGate)
        XCTAssertTrue(self.controller.blocksForwardNavigation(step: self.hard))
        XCTAssertEqual(try self.update(for: "customer-b", activeEntitlements: ["premium"]), .passed)
        XCTAssertFalse(self.controller.hasUnresolvedGate)
    }

    func testIdentityChangeFailsTheGateClosedUntilTheNewUsersInfoArrives() throws {
        self.reset(activeEntitlements: [])
        _ = self.controller.evaluate(step: self.hard)
        _ = try self.update(for: "customer-a", activeEntitlements: ["pro"])
        self.appUserID = "customer-b"

        XCTAssertTrue(self.controller.hasUnresolvedGate)
        XCTAssertEqual(self.outcomes.last, .notPassed)
        XCTAssertTrue(self.controller.blocksForwardNavigation(step: self.hard))
    }

    func testIdentityChangeKeepsPassageWhenTheNewUserHoldsTheEntitlementAsAfterAnAlias() throws {
        self.reset(activeEntitlements: [])
        _ = self.controller.evaluate(step: self.hard)
        _ = try self.update(for: "customer-a", activeEntitlements: ["pro"])
        self.appUserID = "customer-b"

        XCTAssertEqual(try self.update(for: "customer-b", activeEntitlements: ["pro"]), .passed)
        XCTAssertFalse(self.controller.hasUnresolvedGate)
        XCTAssertFalse(self.controller.blocksForwardNavigation(step: self.hard))
        XCTAssertEqual(self.outcomes, [.notApplicable, .notPassed, .passed, .notPassed, .passed])
    }

    func testIdentityChangeRevokesPassageWhenTheNewUserLacksTheEntitlement() throws {
        self.reset(activeEntitlements: [])
        _ = self.controller.evaluate(step: self.hard)
        _ = try self.update(for: "customer-a", activeEntitlements: ["pro"])
        self.appUserID = "customer-b"

        XCTAssertEqual(try self.update(for: "customer-b", activeEntitlements: ["unrelated"]), .blocked)
        XCTAssertTrue(self.controller.hasUnresolvedGate)
        XCTAssertEqual(self.outcomes.last, .notPassed)
    }

    func testCustomerInfoReadForThePreviousUserIsIgnoredAfterAnIdentityChange() throws {
        self.reset(activeEntitlements: [])
        _ = self.controller.evaluate(step: self.hard)
        self.appUserID = "customer-b"

        XCTAssertEqual(try self.update(for: "customer-a", activeEntitlements: ["pro"]), .blocked)
        XCTAssertTrue(self.controller.hasUnresolvedGate)
    }

    func testInfoForAnOutdatedUserIsIgnoredAndALaterOneApplies() throws {
        self.reset(activeEntitlements: [])
        _ = self.controller.evaluate(step: self.hard)
        self.appUserID = "customer-b"
        self.appUserID = "customer-c"

        XCTAssertEqual(try self.update(for: "customer-b", activeEntitlements: ["pro"]), .blocked)
        XCTAssertEqual(try self.update(for: "customer-c", activeEntitlements: ["pro"]), .passed)
    }

    func testInfoAfterAnIdentityChangeBeforeAGateIsReachedSetsTheNewUsersEntryBaseline() throws {
        self.reset(activeEntitlements: ["pro"])
        self.appUserID = "customer-b"

        XCTAssertEqual(try self.update(for: "customer-b", activeEntitlements: ["premium"]), .notGated)
        XCTAssertEqual(self.controller.evaluate(step: self.hard), .passed)
    }

    func testOperationsAreCurrentOnlyForTheActiveAppUserID() {
        self.reset(activeEntitlements: [])

        XCTAssertTrue(self.controller.isCurrentAppUserID("customer-a"))
        self.appUserID = "customer-b"
        XCTAssertFalse(self.controller.isCurrentAppUserID("customer-a"))
    }

    func testResetClearsUnresolvedGateAndOldCallbackOwnership() {
        self.reset(activeEntitlements: [])
        _ = self.controller.evaluate(step: self.hard)
        var nextOutcomes: [CheckpointGateOutcome] = []

        self.controller.reset(context: CheckpointGateContext(
            initialAppUserID: "customer-a",
            initialActiveEntitlementIdentifiers: ["pro"],
            currentAppUserID: { "customer-a" },
            onOutcomeChanged: { nextOutcomes.append($0) }
        ))

        XCTAssertFalse(self.controller.hasUnresolvedGate)
        XCTAssertEqual(self.controller.evaluate(step: self.hard), .passed)
        XCTAssertEqual(self.outcomes, [.notApplicable, .notPassed])
        XCTAssertEqual(nextOutcomes, [.notApplicable, .passed])
    }

    private func update(for appUserID: String, activeEntitlements: [String]) throws -> WorkflowGateDecision {
        return self.controller.update(
            forAppUserID: appUserID,
            customerInfo: try makeCustomerInfo(activeEntitlements: activeEntitlements)
        )
    }

    private func reset(activeEntitlements: Set<String>) {
        self.controller.reset(context: CheckpointGateContext(
            initialAppUserID: "customer-a",
            initialActiveEntitlementIdentifiers: activeEntitlements,
            currentAppUserID: { [unowned self] in self.appUserID },
            onOutcomeChanged: { [unowned self] in self.outcomes.append($0) }
        ))
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
