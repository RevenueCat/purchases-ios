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
final class DefaultCheckpointWorkflowResolverTests: TestCase {

    private let checkpointIdentifier = "test_checkpoint"
    private let params = CheckpointParams()
    private let workflowID = "wf1234"
    private let offeringID = "default"

    private var checkpointsProvider: MockCheckpointsConfigProvider!
    private var workflowsProvider: MockWorkflowsConfigProvider!
    private var workflowManager: WorkflowManager!
    private var offering: Offering!
    private var offerings: Offerings!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.checkpointsProvider = MockCheckpointsConfigProvider()
        self.workflowsProvider = MockWorkflowsConfigProvider()
        self.workflowManager = WorkflowManager(
            workflowsConfigProvider: self.workflowsProvider,
            paywallCache: nil,
            operationDispatcher: MockOperationDispatcher()
        )
        self.checkpointsProvider.result = .success(
            CheckpointRuleSet(rules: [Self.rule(workflowID: self.workflowID)])
        )
        self.workflowsProvider.stubbedOfferingIdByWorkflowId = [self.workflowID: self.offeringID]
        self.workflowsProvider.stubbedGetWorkflowResult = [
            self.workflowID: Self.workflowDataResult(id: self.workflowID)
        ]
        self.offering = Self.offering(id: self.offeringID)
        self.offerings = Self.offerings([self.offering])
    }

    #if DEBUG
    func testSimulatedErrorCheckpointThrowsConfigurationError() async {
        do {
            _ = try await self.resolve(identifier: "error_checkpoint")
            XCTFail("Expected resolution to throw")
        } catch {
            XCTAssertEqual((error as NSError).code, ErrorCode.configurationError.rawValue)
        }
    }
    #endif

    func testDisabledResolverResolvesDisabled() async throws {
        let resolver = DisabledCheckpointWorkflowResolver()

        let resolution = try await resolver.resolve(identifier: self.checkpointIdentifier, params: self.params)

        XCTAssertEqual(Self.noActionReason(resolution), .disabled)
    }

    func testRemoteConfigDisabledResolvesDisabled() async throws {
        self.checkpointsProvider.result = .failure(.remoteConfigDisabled)

        let resolution = try await self.resolve()
        XCTAssertEqual(Self.noActionReason(resolution), .disabled)
    }

    func testUnconfiguredCheckpointResolvesNoMatch() async throws {
        self.checkpointsProvider.result = .success(nil)

        let resolution = try await self.resolve()
        XCTAssertEqual(Self.noActionReason(resolution), .noMatch)
    }

    func testUnavailableRulesResolveConfigurationUnavailable() async throws {
        self.checkpointsProvider.result = .failure(.payloadUnavailable)

        let resolution = try await self.resolve()
        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
    }

    func testCheckpointWithNoRulesResolvesNoMatch() async throws {
        self.checkpointsProvider.result = .success(CheckpointRuleSet(rules: []))

        let resolution = try await self.resolve()
        XCTAssertEqual(Self.noActionReason(resolution), .noMatch)
    }

    func testCheckpointWithNoWorkflowsResolvesConfigurationUnavailable() async throws {
        self.workflowsProvider.stubbedOfferingIdByWorkflowId = [:]

        let resolution = try await self.resolve()
        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
    }

    func testCheckpointResolvesFirstRuleInServedOrder() async throws {
        let secondWorkflowID = "wf5678"
        self.checkpointsProvider.result = .success(CheckpointRuleSet(rules: [
            Self.rule(workflowID: self.workflowID),
            Self.rule(workflowID: secondWorkflowID)
        ]))
        self.workflowsProvider.stubbedOfferingIdByWorkflowId[secondWorkflowID] = self.offeringID
        self.workflowsProvider.stubbedGetWorkflowResult[secondWorkflowID] = Self.workflowDataResult(
            id: secondWorkflowID
        )

        let resolution = try await self.resolve()

        XCTAssertEqual(Self.resolvedWorkflow(resolution)?.workflow.id, self.workflowID)
        XCTAssertEqual(self.workflowsProvider.invokedGetWorkflowParameters, [self.workflowID])
    }

    func testFirstRuleWithoutOfferingMetadataDoesNotFallThrough() async throws {
        let unservableWorkflowID = "wf_without_offering"
        self.checkpointsProvider.result = .success(CheckpointRuleSet(rules: [
            Self.rule(workflowID: unservableWorkflowID),
            Self.rule(workflowID: self.workflowID)
        ]))

        let resolution = try await self.resolve()

        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
        XCTAssertTrue(self.workflowsProvider.invokedGetWorkflowParameters.isEmpty)
    }

    func testFirstRuleWhoseOfferingIsMissingDoesNotFallThrough() async throws {
        let unservableWorkflowID = "wf_missing_offering"
        self.checkpointsProvider.result = .success(CheckpointRuleSet(rules: [
            Self.rule(workflowID: unservableWorkflowID),
            Self.rule(workflowID: self.workflowID)
        ]))
        self.workflowsProvider.stubbedOfferingIdByWorkflowId[unservableWorkflowID] = "missing"

        let resolution = try await self.resolve()

        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
        XCTAssertTrue(self.workflowsProvider.invokedGetWorkflowParameters.isEmpty)
    }

    func testFirstRuleWhoseWorkflowFailsToLoadDoesNotFallThrough() async throws {
        let unavailableWorkflowID = "wf_unavailable"
        self.checkpointsProvider.result = .success(CheckpointRuleSet(rules: [
            Self.rule(workflowID: unavailableWorkflowID),
            Self.rule(workflowID: self.workflowID)
        ]))
        self.workflowsProvider.stubbedOfferingIdByWorkflowId[unavailableWorkflowID] = self.offeringID
        self.workflowsProvider.stubbedGetWorkflowError[unavailableWorkflowID] = .notFound

        let resolution = try await self.resolve()

        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
        XCTAssertEqual(self.workflowsProvider.invokedGetWorkflowParameters, [unavailableWorkflowID])
    }

    func testNoPresentableRuleResolvesConfigurationUnavailable() async throws {
        self.workflowsProvider.stubbedGetWorkflowResult = [:]
        self.workflowsProvider.stubbedGetWorkflowError[self.workflowID] = .notFound

        let resolution = try await self.resolve()
        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
    }

    func testOfferingsFetchFailureResolvesConfigurationUnavailable() async throws {
        let resolver = self.makeResolver {
            throw ErrorUtils.networkError(message: "Offline")
        }

        let resolution = try await resolver.resolve(identifier: self.checkpointIdentifier, params: self.params)

        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
    }

    func testSuccessfulResolutionIncludesWorkflowUIConfigOfferingAndAllOfferings() async throws {
        let secondaryOffering = Self.offering(id: "secondary")
        self.offerings = Self.offerings([self.offering, secondaryOffering])

        let resolution = try await self.resolve()
        let resolved = try XCTUnwrap(Self.resolvedWorkflow(resolution))

        XCTAssertEqual(resolved.workflow.id, self.workflowID)
        XCTAssertEqual(resolved.uiConfig, .empty)
        XCTAssertEqual(resolved.offering.identifier, self.offeringID)
        XCTAssertEqual(Set(resolved.offerings.all.keys), [self.offeringID, secondaryOffering.identifier])
    }

    func testConfigGenerationChangeDuringResolutionReturnsConfigurationUnavailable() async throws {
        let resolver = self.makeResolver {
            self.checkpointsProvider.configGeneration += 1
            return self.offerings
        }

        let resolution = try await resolver.resolve(identifier: self.checkpointIdentifier, params: self.params)

        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
    }

    func testOfferingsAreFetchedOnceForTheMatchingRule() async throws {
        let unavailableWorkflowID = "wf_unavailable"
        self.checkpointsProvider.result = .success(CheckpointRuleSet(rules: [
            Self.rule(workflowID: unavailableWorkflowID),
            Self.rule(workflowID: self.workflowID)
        ]))
        self.workflowsProvider.stubbedOfferingIdByWorkflowId[unavailableWorkflowID] = self.offeringID
        self.workflowsProvider.stubbedGetWorkflowError[unavailableWorkflowID] = .notFound
        let fetchCount = Atomic<Int>(0)
        let resolver = self.makeResolver {
            fetchCount.modify { $0 += 1 }
            return self.offerings
        }

        _ = try await resolver.resolve(identifier: self.checkpointIdentifier, params: self.params)

        XCTAssertEqual(fetchCount.value, 1)
    }

    private func resolve(identifier: String? = nil) async throws -> CheckpointResolution {
        return try await self.makeResolver().resolve(
            identifier: identifier ?? self.checkpointIdentifier,
            params: self.params
        )
    }

    private func makeResolver(
        offeringsProvider: (() async throws -> Offerings)? = nil
    ) -> DefaultCheckpointWorkflowResolver {
        return DefaultCheckpointWorkflowResolver(
            checkpointsConfigProvider: self.checkpointsProvider,
            workflowManager: self.workflowManager,
            offeringsProvider: offeringsProvider ?? { self.offerings }
        )
    }

    private static func noActionReason(_ resolution: CheckpointResolution) -> CheckpointResolutionReason? {
        guard case let .noAction(reason) = resolution else { return nil }
        return reason
    }

    private static func resolvedWorkflow(_ resolution: CheckpointResolution) -> ResolvedCheckpointWorkflow? {
        guard case let .workflow(workflow) = resolution else { return nil }
        return workflow
    }

    private static func rule(workflowID: String) -> CheckpointRule {
        return CheckpointRule(id: "rule_\(workflowID)", audienceId: "audience", workflowId: workflowID)
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

    private static func offering(id: String) -> Offering {
        return Offering(
            identifier: id,
            serverDescription: "Test offering",
            availablePackages: [],
            webCheckoutUrl: nil
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

private final class MockCheckpointsConfigProvider: CheckpointsConfigProviderType {

    var result: Result<CheckpointRuleSet?, CheckpointRulesProviderError> = .success(nil)
    var configGeneration = 0
    private(set) var requestedIdentifiers: [String] = []

    func rules(for identifier: String) async throws -> CheckpointRulesSnapshot? {
        self.requestedIdentifiers.append(identifier)
        return try self.result.get().map {
            CheckpointRulesSnapshot(ruleSet: $0, configGeneration: self.configGeneration)
        }
    }

    func isCurrent(_ snapshot: CheckpointRulesSnapshot) -> Bool {
        return snapshot.configGeneration == self.configGeneration
    }

}
