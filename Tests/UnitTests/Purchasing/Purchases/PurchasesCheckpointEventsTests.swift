//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesCheckpointEventsTests.swift

import Nimble
import XCTest

@_spi(Internal) @testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class PurchasesCheckpointEventsTests: BasePurchasesTests {

    private static let hitDate = Date(timeIntervalSince1970: 1_699_270_688.995)

    override func setUpWithError() throws {
        try super.setUpWithError()
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    func testResolvingCheckpointTracksHit() async throws {
        self.setUpCheckpointPurchases()

        _ = try await self.purchases.resolveCheckpoint(identifier: "onboarding_complete", params: .init())

        let event = try await self.singleTrackedCheckpointEvent()
        expect(event.data.identifier) == "onboarding_complete"
        expect(event.data.date) == Self.hitDate
        expect(event.data.checkpointType) == .custom
    }

    /// The hit is what tells the backend the checkpoint exists, so it has to be reported even when the SDK
    /// has nothing configured to resolve it to.
    func testTracksHitWhenNoWorkflowResolves() async throws {
        self.setUpCheckpointPurchases()

        let resolution = try await self.purchases.resolveCheckpoint(
            identifier: "onboarding_complete",
            params: .init()
        )

        guard case .noAction(.configurationUnavailable) = resolution else {
            fail("Expected resolution to report no action, got \(resolution)")
            return
        }
        let event = try await self.singleTrackedCheckpointEvent()
        expect(event.data.result) == .configurationUnavailable
    }

    func testTracksWhatTheCheckpointResolvedTo() async throws {
        self.setUpCheckpointPurchases(resolver: MatchingCheckpointWorkflowResolver())

        _ = try await self.purchases.resolveCheckpoint(identifier: "onboarding_complete", params: .init())

        let event = try await self.singleTrackedCheckpointEvent()
        expect(event.data.result) == .returnData
        expect(event.data.offeringID) == "onboarding"
        expect(event.data.checkpointRuleID) == "rule_123"
    }

    /// Resolution awaits the network, so the hit has to be dated when the checkpoint was reached.
    func testDatesTheHitBeforeResolving() async throws {
        let afterResolving = Self.hitDate.addingTimeInterval(30)
        self.identityManager.mockIsAnonymous = false
        self.initializePurchasesInstance(
            appUserId: self.identityManager.currentAppUserID,
            checkpointResolver: MatchingCheckpointWorkflowResolver(),
            dateProvider: MockDateProvider(stubbedNow: Self.hitDate, subsequentNows: afterResolving)
        )

        _ = try await self.purchases.resolveCheckpoint(identifier: "onboarding_complete", params: .init())

        let event = try await self.singleTrackedCheckpointEvent()
        expect(event.data.date) == Self.hitDate
    }

    /// A resolution that never completes has no outcome to report, so the identifier goes unregistered.
    func testTracksNothingWhenResolutionFails() async throws {
        self.setUpCheckpointPurchases(resolver: ThrowingCheckpointWorkflowResolver())

        do {
            _ = try await self.purchases.resolveCheckpoint(identifier: "onboarding_complete", params: .init())
            fail("Expected resolution to throw")
        } catch {}

        let tracked = await (try self.mockEventsManager).trackedEvents
        expect(tracked).to(beEmpty())
    }

    // MARK: - Helpers

    private func setUpCheckpointPurchases(
        resolver: CheckpointWorkflowResolver = DisabledCheckpointWorkflowResolver()
    ) {
        self.identityManager.mockIsAnonymous = false
        self.initializePurchasesInstance(
            appUserId: self.identityManager.currentAppUserID,
            checkpointResolver: resolver,
            dateProvider: MockDateProvider(stubbedNow: Self.hitDate)
        )
    }

    private func singleTrackedCheckpointEvent() async throws -> CheckpointEvent {
        let tracked = await (try self.mockEventsManager).trackedEvents
        expect(tracked).to(haveCount(1))
        return try XCTUnwrap(tracked.first as? CheckpointEvent)
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private final class ThrowingCheckpointWorkflowResolver: CheckpointWorkflowResolver {

    private struct ResolutionError: Error {}

    func resolve(identifier: String, params: CheckpointParams) async throws -> ResolvedCheckpoint {
        throw ResolutionError()
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private final class MatchingCheckpointWorkflowResolver: CheckpointWorkflowResolver {

    func resolve(identifier: String, params: CheckpointParams) async throws -> ResolvedCheckpoint {
        let offering = Offering(
            identifier: "onboarding",
            serverDescription: "Onboarding offering",
            availablePackages: [],
            webCheckoutUrl: nil
        )

        return .init(.matchedOffering(offering), checkpointRuleID: "rule_123")
    }

}
