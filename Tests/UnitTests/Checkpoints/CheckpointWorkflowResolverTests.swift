//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointWorkflowResolverTests.swift
//
//  Created by Rick van der Linden.
//

import XCTest

#if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
@_spi(Internal) @testable import RevenueCat_CustomEntitlementComputation
#else
@_spi(Internal) @testable import RevenueCat
#endif

@MainActor
final class RandomWorkflowCheckpointResolverTests: TestCase {

    private let checkpointIdentifier = "test_checkpoint"
    private let params = CheckpointParams()
    private let workflowID = "wf1234"
    private let offeringID = "default"

    private var provider: MockWorkflowsConfigProvider!
    private var workflowManager: WorkflowManager!
    private var offering: Offering!
    private var offerings: Offerings!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.provider = MockWorkflowsConfigProvider()
        self.workflowManager = WorkflowManager(
            workflowsConfigProvider: self.provider,
            paywallCache: nil,
            operationDispatcher: MockOperationDispatcher()
        )
        self.provider.stubbedAvailableWorkflows = [self.workflowID: self.offeringID]
        self.provider.stubbedGetWorkflowResult = [
            self.workflowID: Self.workflowDataResult(id: self.workflowID)
        ]
        self.offering = Offering(
            identifier: self.offeringID,
            serverDescription: "Test offering",
            availablePackages: [],
            webCheckoutUrl: nil
        )
        self.offerings = Self.offerings([self.offering])
    }

    func testSimulatedErrorCheckpointThrowsConfigurationError() async {
        do {
            _ = try await self.resolve(identifier: "error_checkpoint")
            XCTFail("Expected resolution to throw")
        } catch {
            XCTAssertEqual((error as NSError).code, ErrorCode.configurationError.rawValue)
        }
    }

    func testSimulatedUnknownCheckpointResolvesNoMatch() async throws {
        let resolution = try await self.resolve(identifier: "unknown_checkpoint")

        XCTAssertEqual(Self.noActionReason(resolution), .noMatch)
    }

    func testCheckpointResolvesDisabledWhenWorkflowManagerIsMissing() async throws {
        let resolver = RandomWorkflowCheckpointResolver(
            workflowManager: nil,
            getOfferings: { self.offerings }
        )

        let resolution = try await resolver.resolve(identifier: self.checkpointIdentifier, params: self.params)
        XCTAssertEqual(Self.noActionReason(resolution), .disabled)
    }

    func testCheckpointResolvesConfigurationUnavailableWhenNoWorkflowsExist() async throws {
        self.provider.stubbedAvailableWorkflows = [:]

        let resolution = try await self.resolve()
        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
    }

    func testCheckpointResolvesConfigurationUnavailableWhenWorkflowFailsToLoad() async throws {
        self.provider.stubbedGetWorkflowResult = [:]
        self.provider.stubbedGetWorkflowError = [self.workflowID: .notFound]

        let resolution = try await self.resolve()
        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
    }

    func testCheckpointResolvesConfigurationUnavailableWhenOfferingsFetchFails() async throws {
        let resolver = self.makeResolver(getOfferings: {
            throw ErrorUtils.networkError(message: "Offline")
        })

        let resolution = try await resolver.resolve(identifier: self.checkpointIdentifier, params: self.params)
        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
    }

    func testCheckpointResolvesConfigurationUnavailableWhenOfferingIsMissing() async throws {
        let resolver = self.makeResolver(getOfferings: { Self.offerings([]) })

        let resolution = try await resolver.resolve(identifier: self.checkpointIdentifier, params: self.params)
        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
    }

    func testCheckpointBuildsSuccessfulPayloadUsingOfferingFromTopicMetadata() async throws {
        let resolution = try await self.resolve()

        guard case let .workflow(resolvedWorkflow) = resolution else {
            return XCTFail("Expected a resolved workflow")
        }
        XCTAssertEqual(resolvedWorkflow.workflow.id, self.workflowID)
        XCTAssertEqual(resolvedWorkflow.uiConfig, .empty)
        XCTAssertEqual(resolvedWorkflow.offering.identifier, self.offeringID)
        XCTAssertEqual(self.provider.invokedGetWorkflowParameters, [self.workflowID])
    }

    func testCheckpointResolvesConfigurationUnavailableWithoutFetchingOfferingsWhenMetadataHasNone() async throws {
        self.provider.stubbedAvailableWorkflows = [self.workflowID: nil]
        let offeringsFetchCount = Atomic<Int>(0)
        let resolver = self.makeResolver(getOfferings: {
            offeringsFetchCount.modify { $0 += 1 }
            return self.offerings
        })

        let resolution = try await resolver.resolve(identifier: self.checkpointIdentifier, params: self.params)
        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
        XCTAssertEqual(offeringsFetchCount.value, 0)
    }

    private func resolve(identifier: String? = nil) async throws -> CheckpointResolution {
        return try await self.makeResolver().resolve(
            identifier: identifier ?? self.checkpointIdentifier,
            params: self.params
        )
    }

    private func makeResolver(
        getOfferings: RandomWorkflowCheckpointResolver.GetOfferings? = nil
    ) -> RandomWorkflowCheckpointResolver {
        return RandomWorkflowCheckpointResolver(
            workflowManager: self.workflowManager,
            getOfferings: getOfferings ?? { self.offerings },
            chooseWorkflow: { workflows in
                guard workflows.keys.contains(self.workflowID) else { return nil }
                return (self.workflowID, workflows[self.workflowID] ?? nil)
            }
        )
    }

    private static func noActionReason(_ resolution: CheckpointResolution) -> CheckpointResolutionReason? {
        guard case let .noAction(reason) = resolution else { return nil }
        return reason
    }

    private static func workflowDataResult(id: String) -> WorkflowDataResult {
        return WorkflowDataResult(
            workflow: PublishedWorkflow(
                id: id,
                displayName: "Test",
                initialStepId: "step_1",
                singleStepFallbackId: nil,
                steps: ["step_1": WorkflowStep(id: "step_1", type: "screen", screenId: nil)],
                screens: [:]
            ),
            uiConfig: .empty,
            enrolledVariants: nil
        )
    }

    private static func offerings(_ offerings: [Offering]) -> Offerings {
        let response = OfferingsResponse(
            currentOfferingId: nil,
            offerings: [],
            placements: nil,
            targeting: nil,
            uiConfig: nil
        )
        return Offerings(
            offerings: Dictionary(uniqueKeysWithValues: offerings.map { ($0.identifier, $0) }),
            currentOfferingID: nil,
            placements: nil,
            targeting: nil,
            contents: Offerings.Contents(response: response, httpResponseOriginalSource: .mainServer),
            loadedFromDiskCache: false
        )
    }

}
