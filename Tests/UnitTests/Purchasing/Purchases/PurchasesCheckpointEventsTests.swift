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

        let event = try await self.singleTrackedCheckpointEvent()
        expect(event.data.result) == .configurationUnavailable
        expect(event.data.workflowID).to(beNil())
        expect(event.data.offeringID).to(beNil())
        expect(event.data.checkpointRuleID).to(beNil())
    }

    func testTracksNoActionReasonOnTheHit() async throws {
        let reasons: [CheckpointResolutionReason] = [
            .noMatch, .configurationUnavailable, .unknownCheckpoint, .disabled
        ]
        self.setUpCheckpointPurchases(
            resolver: StubCheckpointWorkflowResolver(resolutions: reasons.map { .noAction($0) })
        )

        for _ in reasons {
            _ = try await self.purchases.resolveCheckpoint(identifier: "onboarding_complete", params: .init())
        }

        // `.disabled` has no result of its own: a checkpoint reached with remote config
        // off reports the same thing as configuration that could not be read.
        let tracked = await (try self.mockEventsManager).trackedEvents.compactMap { $0 as? CheckpointEvent }
        expect(tracked.map { $0.data.result }) == [
            .noMatch, .configurationUnavailable, .unknownCheckpoint, .configurationUnavailable
        ]
    }

    func testTracksMatchedOfferingOnTheHit() async throws {
        let offering = Self.offering
        self.setUpCheckpointPurchases(
            resolver: StubCheckpointWorkflowResolver(
                resolution: .matchedOffering(offering),
                checkpointRuleID: "rule_123"
            )
        )

        _ = try await self.purchases.resolveCheckpoint(identifier: "onboarding_complete", params: .init())

        let event = try await self.singleTrackedCheckpointEvent()
        expect(event.data.result) == .offering
        expect(event.data.offeringID) == offering.identifier
        expect(event.data.checkpointRuleID) == "rule_123"
        expect(event.data.workflowID).to(beNil())
    }

    func testTracksMatchedWorkflowOnTheHit() async throws {
        let offering = Self.offering
        let workflow = Self.workflow
        self.setUpCheckpointPurchases(
            resolver: StubCheckpointWorkflowResolver(
                resolution: .matchedWorkflow(.init(
                    workflow: workflow,
                    uiConfig: Self.uiConfig,
                    offering: offering,
                    offerings: .preview(offerings: [offering])
                )),
                checkpointRuleID: "rule_123"
            )
        )

        _ = try await self.purchases.resolveCheckpoint(identifier: "onboarding_complete", params: .init())

        let event = try await self.singleTrackedCheckpointEvent()
        expect(event.data.result) == .workflow
        expect(event.data.workflowID) == workflow.id
        expect(event.data.offeringID) == offering.identifier
        expect(event.data.checkpointRuleID) == "rule_123"
        expect(event.data.date) == Self.hitDate
    }

    /// The hit reports what the checkpoint resolved to, so a resolution that never completes has nothing to
    /// report. Registration of the identifier is lost only in that case.
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

    private static let offering = Offering(
        identifier: "onboarding",
        serverDescription: "Onboarding offering",
        availablePackages: [],
        webCheckoutUrl: nil
    )

    private static let uiConfig = UIConfig(
        app: .init(colors: [:], fonts: [:]),
        localizations: [:],
        variableConfig: .init(variableCompatibilityMap: [:], functionCompatibilityMap: [:])
    )

    private static let workflow = PublishedWorkflow(
        id: "wf_123",
        displayName: "Onboarding",
        initialStepId: "step_1",
        singleStepFallbackId: nil,
        steps: [:],
        screens: [:]
    )

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
private final class StubCheckpointWorkflowResolver: CheckpointWorkflowResolver {

    private let resolved: Atomic<[ResolvedCheckpoint]>

    convenience init(resolution: CheckpointResolution, checkpointRuleID: String? = nil) {
        self.init(resolved: [.init(resolution, checkpointRuleID: checkpointRuleID)])
    }

    convenience init(resolutions: [CheckpointResolution]) {
        self.init(resolved: resolutions.map { .init($0) })
    }

    init(resolved: [ResolvedCheckpoint]) {
        self.resolved = .init(resolved)
    }

    /// Returns each resolution in turn, repeating the last one once they run out.
    func resolve(identifier: String, params: CheckpointParams) async throws -> ResolvedCheckpoint {
        return self.resolved.modify { pending in
            pending.count > 1 ? pending.removeFirst() : pending[0]
        }
    }

}

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private final class ThrowingCheckpointWorkflowResolver: CheckpointWorkflowResolver {

    private struct ResolutionError: Error {}

    func resolve(identifier: String, params: CheckpointParams) async throws -> ResolvedCheckpoint {
        throw ResolutionError()
    }

}
