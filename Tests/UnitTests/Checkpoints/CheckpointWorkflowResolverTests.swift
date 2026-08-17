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

// swiftlint:disable type_body_length

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
    private var audiencesProvider: MockAudiencesConfigProvider!
    private var workflowsProvider: MockWorkflowsConfigProvider!
    private var workflowManager: WorkflowManager!
    private var offering: Offering!
    private var offerings: Offerings!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.checkpointsProvider = MockCheckpointsConfigProvider()
        self.audiencesProvider = MockAudiencesConfigProvider()
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

    func testUnconfiguredCheckpointResolvesUnknownCheckpoint() async throws {
        self.checkpointsProvider.result = .success(nil)

        let resolution = try await self.resolve()
        XCTAssertEqual(Self.noActionReason(resolution), .unknownCheckpoint)
    }

    func testUnavailableRulesResolveConfigurationUnavailable() async throws {
        self.checkpointsProvider.result = .failure(.payloadUnavailable)

        let resolution = try await self.resolve()
        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
    }

    func testCancellationWhileLoadingRulesPropagates() async {
        self.checkpointsProvider.error = CancellationError()

        do {
            _ = try await self.resolve()
            XCTFail("Expected resolution to throw")
        } catch is CancellationError {
            // Expected.
        } catch {
            XCTFail("Expected CancellationError, got \(error)")
        }
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

    func testDimensionProviderFailureResolvesConfigurationUnavailableWithoutFetchingOfferings() async throws {
        let fetchCount = Atomic<Int>(0)
        let evaluator = LocalRulesEvaluator(dimensionProviders: [FailingDimensionProvider()])
        let resolver = self.makeResolver(
            offeringsProvider: {
                fetchCount.modify { $0 += 1 }
                return self.offerings
            },
            localRulesEvaluator: evaluator
        )

        let resolution = try await resolver.resolve(identifier: self.checkpointIdentifier, params: self.params)

        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
        XCTAssertEqual(fetchCount.value, 0)
        XCTAssertTrue(self.workflowsProvider.invokedGetWorkflowParameters.isEmpty)
    }

    func testCancellationWhileCollectingDimensionsPropagates() async {
        let evaluator = LocalRulesEvaluator(dimensionProviders: [CancellingDimensionProvider()])
        let resolver = self.makeResolver(localRulesEvaluator: evaluator)

        do {
            _ = try await resolver.resolve(identifier: self.checkpointIdentifier, params: self.params)
            XCTFail("Expected resolution to throw")
        } catch is CancellationError {
            // Expected.
        } catch {
            XCTFail("Expected CancellationError, got \(error)")
        }
    }

    func testFirstRuleWithoutOfferingMetadataDoesNotFallThrough() async throws {
        let unservableWorkflowID = "wf_without_offering"
        self.checkpointsProvider.result = .success(CheckpointRuleSet(rules: [
            Self.rule(workflowID: unservableWorkflowID),
            Self.rule(workflowID: self.workflowID)
        ]))
        self.workflowsProvider.stubbedGetWorkflowResult[unservableWorkflowID] = Self.workflowDataResult(
            id: unservableWorkflowID
        )

        let resolution = try await self.resolve()

        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
        // The body is read before the offering mapping now, since its shape decides what else the rule needs.
        XCTAssertEqual(self.workflowsProvider.invokedGetWorkflowParameters, [unservableWorkflowID])
    }

    func testFirstRuleWhoseOfferingIsMissingDoesNotFallThrough() async throws {
        let unservableWorkflowID = "wf_missing_offering"
        self.checkpointsProvider.result = .success(CheckpointRuleSet(rules: [
            Self.rule(workflowID: unservableWorkflowID),
            Self.rule(workflowID: self.workflowID)
        ]))
        self.workflowsProvider.stubbedOfferingIdByWorkflowId[unservableWorkflowID] = "missing"
        self.workflowsProvider.stubbedGetWorkflowResult[unservableWorkflowID] = Self.workflowDataResult(
            id: unservableWorkflowID
        )

        let resolution = try await self.resolve()

        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
        XCTAssertEqual(self.workflowsProvider.invokedGetWorkflowParameters, [unservableWorkflowID])
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

    func testNoPresentableRuleResolvesConfigurationUnavailableWithoutFetchingOfferings() async throws {
        self.workflowsProvider.stubbedGetWorkflowResult = [:]
        self.workflowsProvider.stubbedGetWorkflowError[self.workflowID] = .notFound
        let fetchCount = Atomic<Int>(0)
        let resolver = self.makeResolver {
            fetchCount.modify { $0 += 1 }
            return self.offerings
        }

        let resolution = try await resolver.resolve(identifier: self.checkpointIdentifier, params: self.params)

        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
        XCTAssertEqual(fetchCount.value, 0)
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
        let secondWorkflowID = "wf5678"
        self.checkpointsProvider.result = .success(CheckpointRuleSet(rules: [
            Self.rule(workflowID: self.workflowID),
            Self.rule(workflowID: secondWorkflowID)
        ]))
        self.workflowsProvider.stubbedOfferingIdByWorkflowId[secondWorkflowID] = self.offeringID
        self.workflowsProvider.stubbedGetWorkflowResult[secondWorkflowID] = Self.workflowDataResult(
            id: secondWorkflowID
        )
        let fetchCount = Atomic<Int>(0)
        let resolver = self.makeResolver {
            fetchCount.modify { $0 += 1 }
            return self.offerings
        }

        _ = try await resolver.resolve(identifier: self.checkpointIdentifier, params: self.params)

        XCTAssertEqual(fetchCount.value, 1)
    }

    // MARK: - Audience evaluation

    func testFirstRuleWhoseAudienceMatchesDeterminesTheWorkflow() async throws {
        let secondWorkflowID = "wf5678"
        self.stubTwoRules(secondWorkflowID: secondWorkflowID)
        self.audiencesProvider.rulesByAudienceID = [
            "audience_\(self.workflowID)": "false",
            "audience_\(secondWorkflowID)": "true"
        ]

        let resolution = try await self.resolve()

        XCTAssertEqual(Self.resolvedWorkflow(resolution)?.workflow.id, secondWorkflowID)
    }

    func testAudiencesAfterTheFirstMatchAreNotLoaded() async throws {
        let secondWorkflowID = "wf5678"
        self.stubTwoRules(secondWorkflowID: secondWorkflowID)

        _ = try await self.resolve()

        XCTAssertEqual(self.audiencesProvider.requestedIdentifiers, ["audience_\(self.workflowID)"])
    }

    func testCheckpointWhoseAudiencesAllMissMatchesResolvesNoMatch() async throws {
        self.audiencesProvider.defaultRules = "false"

        let resolution = try await self.resolve()

        XCTAssertEqual(Self.noActionReason(resolution), .noMatch)
    }

    /// An audience the SDK couldn't read is not the same answer as one the customer is outside of, so it can't
    /// report `noMatch`, and it can't let a lower-priority rule win either.
    func testMissingAudienceBeforeAMatchResolvesConfigurationUnavailable() async throws {
        let secondWorkflowID = "wf5678"
        self.stubTwoRules(secondWorkflowID: secondWorkflowID)
        self.audiencesProvider.defaultRules = nil
        self.audiencesProvider.rulesByAudienceID = ["audience_\(secondWorkflowID)": "true"]

        let resolution = try await self.resolve()

        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
        XCTAssertTrue(self.workflowsProvider.invokedGetWorkflowParameters.isEmpty)
    }

    func testCustomVariablesAreAvailableToAudiencePredicates() async throws {
        self.audiencesProvider.defaultRules = #"{"==":[{"var":"custom.plan"},"pro"]}"#
        let resolver = self.makeResolver()

        let matched = try await resolver.resolve(
            identifier: self.checkpointIdentifier,
            params: CheckpointParams(customVariables: ["plan": .string("pro")])
        )
        let missed = try await resolver.resolve(
            identifier: self.checkpointIdentifier,
            params: CheckpointParams(customVariables: ["plan": .string("free")])
        )

        XCTAssertEqual(Self.resolvedWorkflow(matched)?.workflow.id, self.workflowID)
        XCTAssertEqual(Self.noActionReason(missed), .noMatch)
    }

    /// A malformed predicate is an evaluation failure, not a lookup failure: the audience was read, the engine
    /// just couldn't run it. That doesn't block a lower-priority rule from winning on its own merits.
    func testMalformedAudienceBeforeAMatchDoesNotPreventALaterWorkflow() async throws {
        let secondWorkflowID = "wf5678"
        self.stubTwoRules(secondWorkflowID: secondWorkflowID)
        self.audiencesProvider.rulesByAudienceID = [
            "audience_\(self.workflowID)": "{not-json",
            "audience_\(secondWorkflowID)": "true"
        ]

        let resolution = try await self.resolve()

        XCTAssertEqual(Self.resolvedWorkflow(resolution)?.workflow.id, secondWorkflowID)
    }

    /// A predicate the engine can't evaluate leaves the customer's membership unknown, so when nothing else
    /// matches, resolution can't claim they simply didn't match.
    func testUnevaluatablePredicateResolvesConfigurationUnavailable() async throws {
        self.audiencesProvider.defaultRules = "{not-json"

        let resolution = try await self.resolve()

        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
    }

    // MARK: - Terminal offering workflows

    func testTerminalOfferingWorkflowResolvesItsOfferingWithoutAWorkflowToPresent() async throws {
        self.stubOfferingWorkflow(offeringID: self.offeringID)

        let resolution = try await self.resolve()

        XCTAssertEqual(Self.resolvedOffering(resolution)?.identifier, self.offeringID)
        XCTAssertNil(Self.resolvedWorkflow(resolution))
    }

    func testTerminalOfferingWorkflowReadsItsOfferingFromTheStepInsteadOfTheWorkflowsMap() async throws {
        let secondaryOffering = Self.offering(id: "secondary")
        self.offerings = Self.offerings([self.offering, secondaryOffering])
        // The workflows topic maps this workflow to a different offering, which the step must win over.
        self.workflowsProvider.stubbedOfferingIdByWorkflowId = [self.workflowID: self.offeringID]
        self.stubOfferingWorkflow(offeringID: secondaryOffering.identifier)

        let resolution = try await self.resolve()

        XCTAssertEqual(Self.resolvedOffering(resolution)?.identifier, secondaryOffering.identifier)
        XCTAssertEqual(self.workflowsProvider.invokedOfferingIdByWorkflowIdCount, 0)
    }

    func testTerminalOfferingWorkflowWhoseOfferingIsUnavailableResolvesConfigurationUnavailable() async throws {
        self.stubOfferingWorkflow(offeringID: "missing")

        let resolution = try await self.resolve()

        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
    }

    private func stubTwoRules(secondWorkflowID: String) {
        self.checkpointsProvider.result = .success(CheckpointRuleSet(rules: [
            Self.rule(workflowID: self.workflowID, audienceID: "audience_\(self.workflowID)"),
            Self.rule(workflowID: secondWorkflowID, audienceID: "audience_\(secondWorkflowID)")
        ]))
        self.workflowsProvider.stubbedOfferingIdByWorkflowId[secondWorkflowID] = self.offeringID
        self.workflowsProvider.stubbedGetWorkflowResult[secondWorkflowID] = Self.workflowDataResult(
            id: secondWorkflowID
        )
    }

    func testOfferingStepWithoutAnOfferingIdentifierResolvesConfigurationUnavailable() async throws {
        self.stubOfferingWorkflow(offeringID: nil)

        let resolution = try await self.resolve()

        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
    }

    func testOfferingStepWithABlankOfferingIdentifierResolvesConfigurationUnavailable() async throws {
        self.stubOfferingWorkflow(offeringID: "   ")

        let resolution = try await self.resolve()

        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
    }

    func testOfferingStepMixedWithAnotherStepResolvesConfigurationUnavailable() async throws {
        self.stubOfferingWorkflow(
            offeringID: self.offeringID,
            extraSteps: ["step_2": WorkflowStep(id: "step_2", type: "screen", screenId: nil)]
        )

        let resolution = try await self.resolve()

        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
    }

    func testWorkflowWhoseInitialStepIsMissingResolvesConfigurationUnavailable() async throws {
        self.stubOfferingWorkflow(offeringID: self.offeringID, initialStepID: "somewhere_else")

        let resolution = try await self.resolve()

        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
    }

    func testUIWorkflowContainingAnOfferingStepResolvesConfigurationUnavailable() async throws {
        // Initial step is the screen step, so the offering step is an unreachable extra.
        self.stubOfferingWorkflow(
            offeringID: self.offeringID,
            initialStepID: "step_2",
            extraSteps: ["step_2": WorkflowStep(id: "step_2", type: "screen", screenId: nil)]
        )

        let resolution = try await self.resolve()

        XCTAssertEqual(Self.noActionReason(resolution), .configurationUnavailable)
    }

    /// Prewarming reads its fonts from `uiConfig`, not from the workflow's screens, so a screenless
    /// offering workflow would still download every app font if it were scheduled here.
    func testTerminalOfferingWorkflowDoesNotScheduleAssetPrewarming() async throws {
        guard #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) else {
            // Without this the assertion would pass vacuously: nothing prewarms below iOS 15.
            throw XCTSkip("prewarmWorkflowAssets requires iOS 15+")
        }

        let cache = MockPaywallCacheWarming()
        self.workflowManager = WorkflowManager(
            workflowsConfigProvider: self.workflowsProvider,
            paywallCache: cache,
            operationDispatcher: MockOperationDispatcher()
        )
        self.stubOfferingWorkflow(offeringID: self.offeringID)

        let resolution = try await self.resolve()

        XCTAssertEqual(Self.resolvedOffering(resolution)?.identifier, self.offeringID)
        XCTAssertFalse(cache.invokedPrewarmWorkflowAssets)
    }

    func testResolvedWorkflowSchedulesAssetPrewarming() async throws {
        guard #available(iOS 15.0, macOS 12.0, watchOS 8.0, tvOS 15.0, *) else {
            throw XCTSkip("prewarmWorkflowAssets requires iOS 15+")
        }

        let cache = MockPaywallCacheWarming()
        self.workflowManager = WorkflowManager(
            workflowsConfigProvider: self.workflowsProvider,
            paywallCache: cache,
            operationDispatcher: MockOperationDispatcher()
        )

        let resolution = try await self.resolve()

        XCTAssertNotNil(Self.resolvedWorkflow(resolution))
        XCTAssertEqual(cache.invokedPrewarmWorkflowAssetIDs, [self.workflowID])
    }

    /// An offering step renders nothing, so anything else it happens to carry is ignored rather than
    /// treated as unservable.
    func testOfferingStepAncillaryFieldsDoNotPreventResolution() async throws {
        self.stubOfferingWorkflow(
            offeringID: self.offeringID,
            screenID: "screen_1",
            triggers: [WorkflowTrigger(name: nil, type: .onPress, actionId: "action_1", componentId: "component_1")],
            triggerActions: ["action_1": .step(stepId: "step_1")]
        )

        let resolution = try await self.resolve()

        XCTAssertEqual(Self.resolvedOffering(resolution)?.identifier, self.offeringID)
    }

    private func stubOfferingWorkflow(
        offeringID: String?,
        initialStepID: String? = nil,
        extraSteps: [String: WorkflowStep] = [:],
        screenID: String? = nil,
        triggers: [WorkflowTrigger] = [],
        triggerActions: [String: WorkflowTriggerAction] = [:]
    ) {
        let stepID = "step_1"
        var step = WorkflowStep(
            id: stepID,
            type: "offering",
            screenId: screenID,
            triggers: triggers,
            triggerActions: triggerActions
        )
        if let offeringID {
            step.paramValues = ["offering_identifier": .string(offeringID)]
        }

        var steps = extraSteps
        steps[stepID] = step

        self.workflowsProvider.stubbedGetWorkflowResult[self.workflowID] = WorkflowDataResult(
            workflow: PublishedWorkflow(
                id: self.workflowID,
                displayName: "Test",
                initialStepId: initialStepID ?? stepID,
                singleStepFallbackId: nil,
                steps: steps,
                screens: [:]
            ),
            uiConfig: .empty,
            enrolledVariants: nil
        )
    }

    private func resolve(identifier: String? = nil) async throws -> CheckpointResolution {
        return try await self.makeResolver().resolve(
            identifier: identifier ?? self.checkpointIdentifier,
            params: self.params
        )
    }

    private func makeResolver(
        offeringsProvider: (() async throws -> Offerings)? = nil,
        localRulesEvaluator: LocalRulesEvaluator = LocalRulesEvaluator(dimensionProviders: [])
    ) -> DefaultCheckpointWorkflowResolver {
        return DefaultCheckpointWorkflowResolver(
            checkpointsConfigProvider: self.checkpointsProvider,
            audiencesConfigProvider: self.audiencesProvider,
            localRulesEvaluator: localRulesEvaluator,
            workflowManager: self.workflowManager,
            offeringsProvider: offeringsProvider ?? { self.offerings }
        )
    }

    private static func noActionReason(_ resolution: CheckpointResolution) -> CheckpointResolutionReason? {
        guard case let .noAction(reason) = resolution else { return nil }
        return reason
    }

    private static func resolvedWorkflow(_ resolution: CheckpointResolution) -> ResolvedCheckpointWorkflow? {
        guard case let .matchedWorkflow(workflow) = resolution else { return nil }
        return workflow
    }

    private static func resolvedOffering(_ resolution: CheckpointResolution) -> Offering? {
        guard case let .matchedOffering(offering) = resolution else { return nil }
        return offering
    }

    private static func rule(workflowID: String, audienceID: String = "audience") -> CheckpointRule {
        return CheckpointRule(id: "rule_\(workflowID)", audienceId: audienceID, workflowId: workflowID)
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

private final class MockAudiencesConfigProvider: AudiencesConfigProviderType {

    /// Every audience matches unless a test says otherwise, so rule ordering stays the subject of the
    /// tests that predate audience evaluation.
    var rulesByAudienceID: [String: String] = [:]
    var defaultRules: String? = "true"
    private(set) var requestedIdentifiers: [String] = []

    func getAudience(_ identifier: String) async -> Audience? {
        self.requestedIdentifiers.append(identifier)

        guard let rules = self.rulesByAudienceID[identifier] ?? self.defaultRules else { return nil }

        return Audience(id: identifier, rules: rules)
    }

}

private struct FailingDimensionProvider: DimensionProvider {

    let namespace = DimensionNamespace.device

    func dimensions(at _: Date) async throws -> [String: DimensionValue] {
        throw FailingDimensionProviderError()
    }

}

private struct FailingDimensionProviderError: Error {}

private struct CancellingDimensionProvider: DimensionProvider {

    let namespace = DimensionNamespace.device

    func dimensions(at _: Date) async throws -> [String: DimensionValue] {
        throw CancellationError()
    }

}

private final class MockCheckpointsConfigProvider: CheckpointsConfigProviderType {

    var result: Result<CheckpointRuleSet?, CheckpointRulesProviderError> = .success(nil)
    var error: Error?
    var configGeneration = 0
    private(set) var requestedIdentifiers: [String] = []

    func rules(for identifier: String) async throws -> CheckpointRulesSnapshot? {
        self.requestedIdentifiers.append(identifier)
        if let error = self.error {
            throw error
        }
        return try self.result.get().map {
            CheckpointRulesSnapshot(ruleSet: $0, configGeneration: self.configGeneration)
        }
    }

    func isCurrent(_ snapshot: CheckpointRulesSnapshot) -> Bool {
        return snapshot.configGeneration == self.configGeneration
    }

}
