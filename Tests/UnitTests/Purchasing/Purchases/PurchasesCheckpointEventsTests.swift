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
    }

    /// The hit is what tells the backend the checkpoint exists, so it has to be reported even when the SDK
    /// has nothing configured to resolve it to.
    func testTracksHitWhenNoWorkflowResolves() async throws {
        self.setUpCheckpointPurchases()

        let resolution = try await self.purchases.resolveCheckpoint(
            identifier: "onboarding_complete",
            params: .init()
        )

        guard case .noAction(.disabled) = resolution else {
            fail("Expected resolution to report no action, got \(resolution)")
            return
        }
        _ = try await self.singleTrackedCheckpointEvent()
    }

    func testTracksHitWhenResolutionFails() async throws {
        self.setUpCheckpointPurchases(resolver: ThrowingCheckpointWorkflowResolver())

        do {
            _ = try await self.purchases.resolveCheckpoint(identifier: "onboarding_complete", params: .init())
            fail("Expected resolution to throw")
        } catch {}

        _ = try await self.singleTrackedCheckpointEvent()
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

    func resolve(identifier: String, params: CheckpointParams) async throws -> CheckpointResolution {
        throw ResolutionError()
    }

}
