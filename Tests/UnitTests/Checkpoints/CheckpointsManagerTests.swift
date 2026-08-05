//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointsManagerTests.swift
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
final class CheckpointsManagerTests: TestCase {

    private let presentableCheckpointIdentifier = "test_checkpoint"

    private var presenter: MockCheckpointPresenter!
    private var listener: MockCheckpointListener!
    private var resolver: MockCheckpointWorkflowResolver!
    private var manager: CheckpointsManager!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.presenter = MockCheckpointPresenter()
        self.listener = MockCheckpointListener()
        self.resolver = MockCheckpointWorkflowResolver()
        self.resolver.presentableIdentifiers = [self.presentableCheckpointIdentifier]
        self.resolver.failedIdentifiers = ["error_checkpoint"]
        self.manager = CheckpointsManager(
            resolver: self.resolver,
            presenterProvider: { self.presenter }
        )
        self.manager.checkpointListener = self.listener
    }

    func testCheckpointParamsDropsInvalidCustomPropertiesWithWarning() {
        let params = CheckpointParams(customProperties: [
            "string": "value",
            "integer": 1,
            "double": 1.5,
            "boolean": true,
            "array": [1, 2, 3],
            "object": NSObject(),
            "null": NSNull()
        ])

        XCTAssertEqual(params.customProperties["string"] as? String, "value")
        XCTAssertEqual(params.customProperties["integer"] as? Int, 1)
        XCTAssertEqual(params.customProperties["double"] as? Double, 1.5)
        XCTAssertEqual(params.customProperties["boolean"] as? Bool, true)
        XCTAssertNil(params.customProperties["array"])
        XCTAssertNil(params.customProperties["object"])
        XCTAssertNil(params.customProperties["null"])

        for key in ["array", "object", "null"] {
            self.logger.verifyMessageWasLogged(
                "Dropping invalid checkpoint custom property '\(key)'",
                level: .warn,
                expectedCount: 1
            )
        }
    }

    func testCheckpointModelsExposeCheckpointAndDebugDescriptions() {
        let params = CheckpointParams()
        let checkpoint = CheckpointInfo(identifier: "test_checkpoint", params: params)
        let result = CheckpointNoActionResult(checkpoint: checkpoint, reason: .noMatch)

        XCTAssertEqual(result.checkpoint.identifier, "test_checkpoint")
        XCTAssertEqual(params.description, "CheckpointParams(customProperties=[:])")
        XCTAssertEqual(
            checkpoint.description,
            "CheckpointInfo(identifier='test_checkpoint', params=CheckpointParams(customProperties=[:]))"
        )
        XCTAssertEqual(
            result.description,
            "NoAction(checkpoint=\(checkpoint), reason=NO_MATCH)"
        )
        XCTAssertEqual(CheckpointPaywallDismissedOutcome.shared.description, "Dismissed")
    }

    #if ENABLE_CHECKPOINTS_OBJC
    func testObjectiveCCheckpointResultWrappersPreserveAssociatedValues() throws {
        let checkpoint = CheckpointInfo(
            identifier: "test_checkpoint",
            params: CheckpointParams(customProperties: ["source": "objective-c"])
        )

        let presented = try XCTUnwrap(
            ObjCCheckpointResult.wrapping(
                CheckpointPaywallPresentedResult(
                    checkpoint: checkpoint,
                    paywallOutcome: CheckpointPaywallDismissedOutcome.shared
                )
            ) as? ObjCCheckpointPaywallPresentedResult
        )
        XCTAssertEqual(presented.checkpoint.identifier, "test_checkpoint")
        XCTAssertEqual(presented.checkpoint.params.customProperties["source"] as? String, "objective-c")
        XCTAssertTrue(presented.paywallOutcome is ObjCCheckpointPaywallDismissedOutcome)

        let noAction = try XCTUnwrap(
            ObjCCheckpointResult.wrapping(
                CheckpointNoActionResult(checkpoint: checkpoint, reason: .frequencyCapped)
            ) as? ObjCCheckpointNoActionResult
        )
        XCTAssertEqual(noAction.reason.value, "FREQUENCY_CAPPED")
    }
    #endif

    func testUnknownCheckpointResolvesNoActionWithNoMatch() {
        let completion = self.expectation(description: "Checkpoint completes")
        var completionResult: CheckpointResult?

        self.manager.checkpoint(identifier: "some_unknown_checkpoint", params: nil) { result in
            completionResult = try? result.get()
            self.listener.events.append(.completion)
            completion.fulfill()
        }

        self.waitForExpectations(timeout: 1)

        guard let noAction = completionResult as? CheckpointNoActionResult else {
            return XCTFail("Expected a no-action result")
        }
        XCTAssertEqual(noAction.reason, .noMatch)
        XCTAssertEqual(noAction.checkpoint.identifier, "some_unknown_checkpoint")
        XCTAssertEqual(
            self.listener.events,
            [
                .hit("some_unknown_checkpoint"),
                .completed("some_unknown_checkpoint"),
                .completion
            ]
        )
    }

    func testSimulatedErrorCheckpointCompletesWithConfigurationError() {
        let completion = self.expectation(description: "Checkpoint errors")

        self.manager.checkpoint(identifier: "error_checkpoint", params: nil) { result in
            guard case let .failure(error) = result else {
                return XCTFail("Expected checkpoint to fail")
            }
            XCTAssertEqual(error.code, ErrorCode.configurationError.rawValue)
            completion.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

    func testAwaitingSimulatedErrorCheckpointThrowsConfigurationError() async {
        do {
            _ = try await self.manager.checkpoint(identifier: "error_checkpoint", params: nil)
            XCTFail("Expected checkpoint to throw")
        } catch {
            XCTAssertEqual((error as NSError).code, ErrorCode.configurationError.rawValue)
        }
    }

    func testPresentableCheckpointErrorsWhenPresenterIsMissing() {
        self.manager = CheckpointsManager(resolver: self.resolver, presenterProvider: { nil })
        let completion = self.expectation(description: "Checkpoint errors")

        self.manager.checkpoint(identifier: self.presentableCheckpointIdentifier, params: nil) { result in
            guard case let .failure(error) = result else {
                return XCTFail("Expected checkpoint to fail")
            }
            XCTAssertEqual(error.code, ErrorCode.configurationError.rawValue)
            completion.fulfill()
        }

        self.waitForExpectations(timeout: 1)
    }

    func testPresenterProviderCanPresentCheckpoint() async throws {
        self.manager = CheckpointsManager(
            resolver: self.resolver,
            presenterProvider: { self.presenter }
        )
        self.presenter.onPresent = { presentation in
            presentation.delegate.onCheckpointPaywallFinished(
                callID: presentation.callID,
                outcome: CheckpointPaywallDismissedOutcome.shared
            )
        }

        let result = try await self.manager.checkpoint(
            identifier: self.presentableCheckpointIdentifier,
            params: nil
        )

        guard let presented = result as? CheckpointPaywallPresentedResult,
              presented.paywallOutcome is CheckpointPaywallDismissedOutcome else {
            return XCTFail("Expected a paywall-presented result")
        }
    }

    func testPresenterReceivesResolvedPresentationForCheckpointIdentifier() async throws {
        self.resolver.presentableIdentifiers.insert("soft_paywall")
        self.presenter.onPresent = { presentation in
            XCTAssertEqual(presentation.workflowPresentation.checkpoint.identifier, "soft_paywall")
            presentation.delegate.onCheckpointPaywallFinished(
                callID: presentation.callID,
                outcome: CheckpointPaywallDismissedOutcome.shared
            )
        }

        _ = try await self.manager.checkpoint(
            identifier: "soft_paywall",
            params: CheckpointParams(customProperties: ["name": "Rick"])
        )
    }

    func testCheckpointWithoutAvailableWorkflowDataResolvesConfigurationUnavailable() async throws {
        self.resolver.noMatchReason = .configurationUnavailable
        self.resolver.presentableIdentifiers = []

        let result = try await self.manager.checkpoint(
            identifier: self.presentableCheckpointIdentifier,
            params: nil
        )

        guard let noAction = result as? CheckpointNoActionResult else {
            return XCTFail("Expected a no-action result")
        }
        XCTAssertEqual(noAction.reason, .configurationUnavailable)
    }

    func testPresentableCheckpointResolvesPaywallPresentedWhenPaywallFinishes() async throws {
        let completion = self.expectation(description: "Checkpoint completes")
        let presentationStarted = self.expectation(description: "Checkpoint presentation starts")
        var completionResult: CheckpointResult?
        let params = CheckpointParams(customProperties: ["goal": "test"])
        self.presenter.onPresent = { _ in presentationStarted.fulfill() }

        self.manager.checkpoint(
            identifier: self.presentableCheckpointIdentifier,
            params: params
        ) { result in
            completionResult = try? result.get()
            self.listener.events.append(.completion)
            completion.fulfill()
        }

        XCTAssertNil(completionResult)
        await self.fulfillment(of: [presentationStarted], timeout: 1)
        let presentation = try XCTUnwrap(self.presenter.presentations.first)
        presentation.delegate.onCheckpointPaywallFinished(
            callID: presentation.callID,
            outcome: CheckpointPaywallDismissedOutcome.shared
        )
        await self.fulfillment(of: [completion], timeout: 1)

        guard let presented = completionResult as? CheckpointPaywallPresentedResult else {
            return XCTFail("Expected a paywall-presented result")
        }
        XCTAssertEqual(presented.checkpoint.identifier, self.presentableCheckpointIdentifier)
        XCTAssertEqual(presented.checkpoint.params.customProperties["goal"] as? String, "test")
        XCTAssertTrue(presented.paywallOutcome is CheckpointPaywallDismissedOutcome)
        XCTAssertEqual(
            self.listener.events,
            [
                .hit("test_checkpoint"),
                .completed("test_checkpoint"),
                .completion
            ]
        )
    }

    func testAwaitingPresentableCheckpointResolvesPaywallPresentedWhenPaywallFinishes() async throws {
        self.presenter.onPresent = { presentation in
            presentation.delegate.onCheckpointPaywallFinished(
                callID: presentation.callID,
                outcome: CheckpointPaywallDismissedOutcome.shared
            )
        }

        let result = try await self.manager.checkpoint(
            identifier: self.presentableCheckpointIdentifier,
            params: nil
        )

        guard let presented = result as? CheckpointPaywallPresentedResult else {
            return XCTFail("Expected a paywall-presented result")
        }
        XCTAssertEqual(presented.checkpoint.identifier, self.presentableCheckpointIdentifier)
        XCTAssertTrue(presented.paywallOutcome is CheckpointPaywallDismissedOutcome)
    }

    func testConcurrentCheckpointErrorsWhilePresenting() async throws {
        let firstCheckpoint = Task {
            try await self.manager.checkpoint(
                identifier: self.presentableCheckpointIdentifier,
                params: nil
            )
        }
        await Task.yield()

        do {
            _ = try await self.manager.checkpoint(
                identifier: self.presentableCheckpointIdentifier,
                params: nil
            )
            XCTFail("Expected concurrent checkpoint to throw")
        } catch {
            XCTAssertEqual(
                (error as NSError).code,
                ErrorCode.operationAlreadyInProgressForProductError.rawValue
            )
            XCTAssertEqual(
                error.localizedDescription,
                "Another checkpoint experience is already being presented."
            )
        }

        let presentation = try XCTUnwrap(self.presenter.presentations.first)
        presentation.delegate.onCheckpointPaywallFinished(
            callID: presentation.callID,
            outcome: CheckpointPaywallDismissedOutcome.shared
        )
        _ = try await firstCheckpoint.value
    }

    func testCheckpointCanPresentAgainAfterPreviousUIFinishes() async throws {
        self.presenter.onPresent = { presentation in
            presentation.delegate.onCheckpointPaywallFinished(
                callID: presentation.callID,
                outcome: CheckpointPaywallDismissedOutcome.shared
            )
        }

        _ = try await self.manager.checkpoint(
            identifier: self.presentableCheckpointIdentifier,
            params: nil
        )
        _ = try await self.manager.checkpoint(
            identifier: self.presentableCheckpointIdentifier,
            params: nil
        )

        XCTAssertEqual(self.presenter.presentations.count, 2)
    }

    func testCheckpointCanPresentAgainAfterPreviousCallIsCancelled() async throws {
        let firstPresentationStarted = self.expectation(description: "First presentation starts")
        self.presenter.onPresent = { _ in firstPresentationStarted.fulfill() }
        let firstCheckpoint = Task {
            try await self.manager.checkpoint(
                identifier: self.presentableCheckpointIdentifier,
                params: nil
            )
        }
        await self.fulfillment(of: [firstPresentationStarted], timeout: 1)

        firstCheckpoint.cancel()
        do {
            _ = try await firstCheckpoint.value
            XCTFail("Expected cancelled checkpoint to throw")
        } catch is CancellationError {
            // Expected.
        }

        self.presenter.onPresent = { presentation in
            presentation.delegate.onCheckpointPaywallFinished(
                callID: presentation.callID,
                outcome: CheckpointPaywallDismissedOutcome.shared
            )
        }
        _ = try await self.manager.checkpoint(
            identifier: self.presentableCheckpointIdentifier,
            params: nil
        )

        XCTAssertEqual(self.presenter.presentations.count, 2)
    }

    func testUIFinishedReportForUnknownCallIDIsNoOp() {
        let executor = UICheckpointWorkflowExecutor(presenterProvider: { self.presenter })

        executor.onCheckpointPaywallFinished(
            callID: "unknown-call-id",
            outcome: CheckpointPaywallDismissedOutcome.shared
        )

        XCTAssertTrue(self.presenter.presentations.isEmpty)
        XCTAssertTrue(self.listener.events.isEmpty)
    }

}

@MainActor
final class RandomWorkflowCheckpointResolverTests: TestCase {

    private let checkpoint = CheckpointInfo(identifier: "test_checkpoint", params: .init())
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

    func testSimulatedErrorCheckpointFailsWithConfigurationError() async {
        let resolution = await self.makeResolver().resolve(
            checkpoint: CheckpointInfo(identifier: "error_checkpoint", params: .init())
        )

        guard case let .failed(error) = resolution else {
            return XCTFail("Expected a failed resolution")
        }
        XCTAssertEqual(error.errorCode, .configurationError)
    }

    func testSimulatedUnknownCheckpointResolvesNoMatch() async {
        let resolution = await self.makeResolver().resolve(
            checkpoint: CheckpointInfo(identifier: "unknown_checkpoint", params: .init())
        )

        XCTAssertEqual(Self.noMatchReason(resolution), .noMatch)
    }

    func testCheckpointResolvesDisabledWhenWorkflowManagerIsMissing() async {
        let resolver = RandomWorkflowCheckpointResolver(
            workflowManager: nil,
            getOfferings: { self.offerings }
        )

        XCTAssertEqual(Self.noMatchReason(await resolver.resolve(checkpoint: self.checkpoint)), .disabled)
    }

    func testCheckpointResolvesConfigurationUnavailableWhenNoWorkflowsExist() async {
        self.provider.stubbedAvailableWorkflows = [:]

        XCTAssertEqual(
            Self.noMatchReason(await self.makeResolver().resolve(checkpoint: self.checkpoint)),
            .configurationUnavailable
        )
    }

    func testCheckpointResolvesConfigurationUnavailableWhenWorkflowFailsToLoad() async {
        self.provider.stubbedGetWorkflowResult = [:]
        self.provider.stubbedGetWorkflowError = [self.workflowID: .notFound]

        XCTAssertEqual(
            Self.noMatchReason(await self.makeResolver().resolve(checkpoint: self.checkpoint)),
            .configurationUnavailable
        )
    }

    func testCheckpointResolvesConfigurationUnavailableWhenOfferingsFetchFails() async {
        let resolver = self.makeResolver(getOfferings: {
            throw ErrorUtils.networkError(message: "Offline")
        })

        XCTAssertEqual(
            Self.noMatchReason(await resolver.resolve(checkpoint: self.checkpoint)),
            .configurationUnavailable
        )
    }

    func testCheckpointResolvesConfigurationUnavailableWhenOfferingIsMissing() async {
        let resolver = self.makeResolver(getOfferings: { Self.offerings([]) })

        XCTAssertEqual(
            Self.noMatchReason(await resolver.resolve(checkpoint: self.checkpoint)),
            .configurationUnavailable
        )
    }

    func testCheckpointBuildsSuccessfulPayloadUsingOfferingFromTopicMetadata() async {
        let resolution = await self.makeResolver().resolve(checkpoint: self.checkpoint)

        guard case let .matched(presentation) = resolution,
              let presentation = presentation as? ResolvedCheckpointWorkflowPresentation else {
            return XCTFail("Expected a matched resolved-workflow presentation")
        }
        XCTAssertEqual(presentation.checkpoint, self.checkpoint)
        XCTAssertEqual(presentation.workflow.id, self.workflowID)
        XCTAssertEqual(presentation.uiConfig, .empty)
        XCTAssertEqual(presentation.offering.identifier, self.offeringID)
        XCTAssertEqual(self.provider.invokedGetWorkflowParameters, [self.workflowID])
    }

    func testCheckpointResolvesConfigurationUnavailableWithoutFetchingOfferingsWhenMetadataHasNone() async {
        self.provider.stubbedAvailableWorkflows = [self.workflowID: nil]
        let offeringsFetchCount = Atomic<Int>(0)
        let resolver = self.makeResolver(getOfferings: {
            offeringsFetchCount.modify { $0 += 1 }
            return self.offerings
        })

        XCTAssertEqual(
            Self.noMatchReason(await resolver.resolve(checkpoint: self.checkpoint)),
            .configurationUnavailable
        )
        XCTAssertEqual(offeringsFetchCount.value, 0)
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

    private static func noMatchReason(_ resolution: CheckpointWorkflowResolution) -> CheckpointNoActionReason? {
        guard case let .noMatch(reason) = resolution else { return nil }
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

private final class MockCheckpointPresenter: CheckpointPresenter {

    struct Presentation {
        let callID: String
        let workflowPresentation: CheckpointWorkflowPresentation
        let delegate: CheckpointPresenterDelegate
    }

    private(set) var presentations: [Presentation] = []
    var onPresent: ((Presentation) -> Void)?

    func present(
        callID: String,
        presentation: CheckpointWorkflowPresentation,
        delegate: CheckpointPresenterDelegate
    ) {
        let presentation = Presentation(
            callID: callID,
            workflowPresentation: presentation,
            delegate: delegate
        )
        self.presentations.append(presentation)
        self.onPresent?(presentation)
    }

}

private final class MockCheckpointWorkflowResolver: CheckpointWorkflowResolver {

    var presentableIdentifiers: Set<String> = []
    var failedIdentifiers: Set<String> = []
    var noMatchReason: CheckpointNoActionReason = .noMatch

    func resolve(checkpoint: CheckpointInfo) async -> CheckpointWorkflowResolution {
        if self.failedIdentifiers.contains(checkpoint.identifier) {
            return .failed(
                ErrorUtils.configurationError(
                    message: "Unable to resolve checkpoint workflow."
                )
            )
        }

        if self.presentableIdentifiers.contains(checkpoint.identifier) {
            return .matched(CheckpointWorkflowPresentation(checkpoint: checkpoint))
        }

        return .noMatch(self.noMatchReason)
    }

}

private final class MockCheckpointListener: CheckpointListener {

    enum Event: Equatable {
        case hit(String)
        case completed(String)
        case completion
    }

    var events: [Event] = []

    func onCheckpointHit(_ checkpoint: CheckpointInfo) {
        self.events.append(.hit(checkpoint.identifier))
    }

    func onCheckpointCompleted(_ checkpoint: CheckpointInfo, result: CheckpointResult) {
        self.events.append(.completed(checkpoint.identifier))
    }

}
