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

    func testPurchaseCompletionRequiresAQualifyingOperation() throws {
        XCTAssertTrue(self.controller.beginEntry(step: self.hard))
        self.controller.beginOperation(appUserID: "customer")

        let blocked = self.controller.completeOperation(
            customerInfo: try CheckpointTestFixtures.customerInfo(activeEntitlements: ["unrelated"]),
            appUserID: "customer", isPresentationHidden: false, isPurchase: true
        )
        XCTAssertEqual(self.controller.status, .notPassed)
        XCTAssertEqual(blocked, .none)

        self.controller.beginOperation(appUserID: "customer")
        let passed = self.controller.completeOperation(
            customerInfo: try CheckpointTestFixtures.customerInfo(activeEntitlements: ["pro"]),
            appUserID: "customer", isPresentationHidden: false, isPurchase: true
        )
        XCTAssertEqual(self.controller.status, .passed)
        XCTAssertEqual(passed, .completeGate)
    }

    func testQualifyingRestoreCompletesGate() throws {
        XCTAssertTrue(self.controller.beginEntry(step: self.hard))
        self.controller.beginOperation(appUserID: "customer")

        let completion = self.controller.completeOperation(
            customerInfo: try CheckpointTestFixtures.customerInfo(activeEntitlements: ["pro"]),
            appUserID: "customer", isPresentationHidden: false, isPurchase: false
        )

        XCTAssertEqual(self.controller.status, .passed)
        XCTAssertEqual(completion, .completeGate)
    }

    func testUngatedPurchaseDismissesButRestoreDoesNot() throws {
        for isPurchase in [true, false] {
            self.controller.beginOperation(appUserID: "customer")
            let completion = self.controller.completeOperation(
                customerInfo: try CheckpointTestFixtures.customerInfo(activeEntitlements: []),
                appUserID: "customer", isPresentationHidden: false, isPurchase: isPurchase
            )
            XCTAssertEqual(completion, isPurchase ? .dismissWorkflow : .none)
        }
    }

    func testPurchaseCannotDismissWhileInitialBranchIsPending() throws {
        self.controller.markInitialBranchPending()
        self.controller.beginOperation(appUserID: "customer")

        let completion = self.controller.completeOperation(
            customerInfo: try CheckpointTestFixtures.customerInfo(activeEntitlements: ["pro"]),
            appUserID: "customer", isPresentationHidden: false, isPurchase: true
        )

        XCTAssertEqual(completion, .none)
        XCTAssertEqual(self.controller.status, .notPassed)
    }

    func testOperationFromDifferentCustomerCannotPassGateAndResumesPendingEntry() throws {
        for isPurchase in [true, false] {
            var resumedEntry = false
            let entryTask = try self.startPendingEntry { _ in resumedEntry = true }
            self.controller.beginOperation(appUserID: "customer-a")

            let completion = self.controller.completeOperation(
                customerInfo: try CheckpointTestFixtures.customerInfo(activeEntitlements: ["pro"]),
                appUserID: "customer-b", isPresentationHidden: false, isPurchase: isPurchase
            )

            XCTAssertEqual(self.controller.status, .notPassed)
            XCTAssertEqual(completion, .none)
            XCTAssertTrue(resumedEntry)
            XCTAssertTrue(entryTask.isCancelled)
            XCTAssertNil(self.controller.entryTask)
        }
    }

    func testBlockedOperationCancelsEntryReadAndResumesItsDestination() throws {
        var resumedEntry = false
        let entryTask = try self.startPendingEntry { _ in resumedEntry = true }
        self.controller.beginOperation(appUserID: "customer")

        let completion = self.controller.completeOperation(
            customerInfo: try CheckpointTestFixtures.customerInfo(activeEntitlements: []),
            appUserID: "customer", isPresentationHidden: false, isPurchase: true
        )

        XCTAssertEqual(completion, .none)
        XCTAssertTrue(entryTask.isCancelled)
        XCTAssertNil(self.controller.entryTask)
        XCTAssertTrue(resumedEntry)
        XCTAssertEqual(self.controller.status, .notPassed)
    }

    func testHiddenOperationsWaitUntilDeferredResultIsApplied() throws {
        for isPurchase in [true, false] {
            var resumedEntry = false
            _ = try self.startPendingEntry { _ in resumedEntry = true }
            self.controller.beginOperation(appUserID: "customer")

            let completion = self.controller.completeOperation(
                customerInfo: try CheckpointTestFixtures.customerInfo(activeEntitlements: ["pro"]),
                appUserID: "customer", isPresentationHidden: true, isPurchase: isPurchase
            )

            XCTAssertEqual(self.controller.status, .notPassed)
            XCTAssertEqual(completion, .none)
            XCTAssertFalse(resumedEntry)
            XCTAssertEqual(self.controller.applyDeferredOperation(), .completeGate)
            XCTAssertEqual(self.controller.status, .passed)
            XCTAssertTrue(self.controller.beginEntry(step: self.hard))
            XCTAssertEqual(self.controller.applyDeferredOperation(), .none)
            XCTAssertEqual(self.controller.status, .notPassed)
        }
    }

    func testCancellingPendingWorkDiscardsDeferredResultAndEntryRead() throws {
        XCTAssertTrue(self.controller.beginEntry(step: self.hard))
        self.controller.beginOperation(appUserID: "customer")
        _ = self.controller.completeOperation(
            customerInfo: try CheckpointTestFixtures.customerInfo(activeEntitlements: ["pro"]),
            appUserID: "customer", isPresentationHidden: true, isPurchase: true
        )
        var resumedEntry = false
        let entryTask = try self.startPendingEntry { _ in resumedEntry = true }

        self.controller.cancelPendingWork()

        XCTAssertEqual(self.controller.applyDeferredOperation(), .none)
        XCTAssertEqual(self.controller.status, .notPassed)
        XCTAssertTrue(entryTask.isCancelled)
        XCTAssertNil(self.controller.entryTask)
        XCTAssertFalse(resumedEntry)
    }

    func testEntryReadsEntitlementsAndClearsTaskBeforeCompleting() async throws {
        var decision: WorkflowGateDecision?
        var taskWasCleared = false
        self.controller.enter(
            step: self.hard,
            customerInfo: { try CheckpointTestFixtures.customerInfo(activeEntitlements: ["pro"]) },
            appUserID: { "customer" },
            canApplyResult: { true },
            completion: {
                decision = $0
                taskWasCleared = self.controller.entryTask == nil
            }
        )
        XCTAssertEqual(self.controller.status, .notPassed)
        let task = try XCTUnwrap(self.controller.entryTask)

        await task.value

        XCTAssertEqual(decision, .passed)
        XCTAssertTrue(taskWasCleared)
        XCTAssertEqual(self.controller.status, .passed)
    }

    func testFailedEntryReadRendersBlockedDestinationAndClearsTask() async throws {
        var decision: WorkflowGateDecision?
        self.controller.enter(
            step: self.hard,
            customerInfo: { throw CancellationError() },
            appUserID: { "customer" },
            canApplyResult: { true },
            completion: { decision = $0 }
        )
        let task = try XCTUnwrap(self.controller.entryTask)

        await task.value

        XCTAssertEqual(decision, .blocked)
        XCTAssertNil(self.controller.entryTask)
        XCTAssertEqual(self.controller.status, .notPassed)
    }

    func testUngatedEntryDoesNotReadCustomerInfo() {
        var decision: WorkflowGateDecision?
        self.controller.enter(
            step: Self.step(nil),
            customerInfo: {
                XCTFail("Ungated entry should not read customer info")
                throw CancellationError()
            },
            appUserID: { "customer" },
            canApplyResult: { true },
            completion: { decision = $0 }
        )

        XCTAssertEqual(decision, .notGated)
        XCTAssertNil(self.controller.entryTask)
    }

    func testEntryThatCanNoLongerApplyClearsTaskWithoutCompleting() async throws {
        var completed = false
        self.controller.enter(
            step: self.hard,
            customerInfo: { try CheckpointTestFixtures.customerInfo(activeEntitlements: ["pro"]) },
            appUserID: { "customer" },
            canApplyResult: { false },
            completion: { _ in completed = true }
        )
        let task = try XCTUnwrap(self.controller.entryTask)

        await task.value

        XCTAssertFalse(completed)
        XCTAssertNil(self.controller.entryTask)
        XCTAssertEqual(self.controller.status, .notPassed)
    }

    func testCancelledEntryCannotClearReplacementTask() async throws {
        var completedFirstEntry = false
        let firstTask = try self.startPendingEntry { _ in completedFirstEntry = true }
        let secondTask = try self.startPendingEntry()

        await firstTask.value

        XCTAssertTrue(firstTask.isCancelled)
        XCTAssertFalse(completedFirstEntry)
        XCTAssertNotNil(self.controller.entryTask)
        XCTAssertFalse(secondTask.isCancelled)
        self.controller.cancelEntry()
        await secondTask.value
        XCTAssertNil(self.controller.entryTask)
    }

    private func startPendingEntry(
        completion: @escaping @MainActor (WorkflowGateDecision) -> Void = { _ in }
    ) throws -> Task<Void, Never> {
        self.controller.enter(
            step: self.hard,
            customerInfo: {
                try await Task.sleep(nanoseconds: 60_000_000_000)
                return try CheckpointTestFixtures.customerInfo(activeEntitlements: [])
            },
            appUserID: { "customer" },
            canApplyResult: { true },
            completion: completion
        )
        return try XCTUnwrap(self.controller.entryTask)
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
