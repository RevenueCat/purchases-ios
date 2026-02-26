//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EventsManagerTests.swift
//
//  Created by Nacho Soto on 9/6/23.

import Foundation
import Nimble

@_spi(Internal) @testable import RevenueCat

import XCTest

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class EventsManagerTests: TestCase {

    private var api: MockInternalAPI!
    private var userProvider: MockCurrentUserProvider!
    private var store: MockFeatureEventStore!
    private var manager: EventsManager!
    private var appSessionID = UUID()

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.api = .init()
        self.userProvider = .init(mockAppUserID: Self.userID)
        self.store = .init()
        self.manager = .init(
            internalAPI: self.api,
            userProvider: self.userProvider,
            store: self.store,
            systemInfo: MockSystemInfo(finishTransactions: true),
            appSessionID: self.appSessionID,
            adEventStore: nil
        )
    }

    func createManagerWithAdEvents() {
        let adEventStore = MockAdEventStore()
        self.manager = .init(
            internalAPI: self.api,
            userProvider: self.userProvider,
            store: self.store,
            systemInfo: MockSystemInfo(finishTransactions: true),
            appSessionID: self.appSessionID,
            adEventStore: adEventStore
        )
    }

    // MARK: - trackEvent

    func testTrackEvent() async throws {
        let event: PaywallEvent = .impression(.random(), .random())

        await self.manager.track(featureEvent: event)

        let events = await self.store.storedEvents
        expect(events) == [
            try createStoredFeatureEvent(from: event)
        ]
    }

    func testTrackMultipleEvents() async throws {
        let event1: PaywallEvent = .impression(.random(), .random())
        let event2: PaywallEvent = .close(.random(), .random())

        await self.manager.track(featureEvent: event1)
        await self.manager.track(featureEvent: event2)

        let events = await self.store.storedEvents
        expect(events) == [
            try createStoredFeatureEvent(from: event1),
            try createStoredFeatureEvent(from: event2)
        ]
    }

    /// We should remove this test once we support the purchase initiated event in the backend.
    func testTrackPurchaseInitiatedEventDoesNotStore() async throws {
        let event: PaywallEvent = .purchaseInitiated(.random(), .random())

        await self.manager.track(featureEvent: event)

        await self.verifyEmptyStore()
    }

    /// We should remove this test once we support the purchase error event in the backend.
    func testTrackPurchaseErrorEventDoesNotStore() async throws {
        let event: PaywallEvent = .purchaseError(.random(), .random())

        await self.manager.track(featureEvent: event)

        await self.verifyEmptyStore()
    }

    // MARK: - toMap (Paywall Events)

    func testPaywallImpressionToMap() {
        let creationData = PaywallEvent.CreationData.random()
        let data = PaywallEvent.Data.random()
        let event: PaywallEvent = .impression(creationData, data)
        let map = event.toMap()

        expect(map["discriminator"] as? String) == "paywalls"
        expect(map["type"] as? String) == "paywall_impression"
        expect(map["id"] as? String) == creationData.id.uuidString
        expect(map["timestamp"] as? UInt64) == creationData.date.millisecondsSince1970
        expect(map["offering_id"] as? String) == data.offeringIdentifier
        expect(map["paywall_revision"] as? Int) == data.paywallRevision
        expect(map["session_id"] as? String) == data.sessionIdentifier.uuidString
        expect(map["display_mode"] as? String) == data.displayMode.identifier
        expect(map["locale"] as? String) == data.localeIdentifier
        expect(map["dark_mode"] as? Bool) == data.darkMode
    }

    func testPaywallCloseToMap() {
        let creationData = PaywallEvent.CreationData.random()
        let data = PaywallEvent.Data.random()
        let event: PaywallEvent = .close(creationData, data)
        let map = event.toMap()

        expect(map["discriminator"] as? String) == "paywalls"
        expect(map["type"] as? String) == "paywall_close"
        expect(map["id"] as? String) == creationData.id.uuidString
        expect(map["timestamp"] as? UInt64) == creationData.date.millisecondsSince1970
        expect(map["offering_id"] as? String) == data.offeringIdentifier
        expect(map["paywall_revision"] as? Int) == data.paywallRevision
        expect(map["session_id"] as? String) == data.sessionIdentifier.uuidString
        expect(map["display_mode"] as? String) == data.displayMode.identifier
        expect(map["locale"] as? String) == data.localeIdentifier
        expect(map["dark_mode"] as? Bool) == data.darkMode
    }

    func testPaywallCancelToMap() {
        let creationData = PaywallEvent.CreationData.random()
        let data = PaywallEvent.Data.random()
        let event: PaywallEvent = .cancel(creationData, data)
        let map = event.toMap()

        expect(map["discriminator"] as? String) == "paywalls"
        expect(map["type"] as? String) == "paywall_cancel"
        expect(map["id"] as? String) == creationData.id.uuidString
        expect(map["timestamp"] as? UInt64) == creationData.date.millisecondsSince1970
        expect(map["session_id"] as? String) == data.sessionIdentifier.uuidString
    }

    func testPaywallExitOfferToMap() {
        let creationData = PaywallEvent.CreationData.random()
        let data = PaywallEvent.Data.random()
        let exitOfferData = PaywallEvent.ExitOfferData(
            exitOfferType: .dismiss,
            exitOfferingIdentifier: "exit_offering"
        )
        let event: PaywallEvent = .exitOffer(creationData, data, exitOfferData)
        let map = event.toMap()

        expect(map["discriminator"] as? String) == "paywalls"
        expect(map["type"] as? String) == "paywall_exit_offer"
        expect(map["id"] as? String) == creationData.id.uuidString
        expect(map["timestamp"] as? UInt64) == creationData.date.millisecondsSince1970
        expect(map["session_id"] as? String) == data.sessionIdentifier.uuidString
    }

    func testPaywallPurchaseInitiatedToMap() {
        let creationData = PaywallEvent.CreationData.random()
        let data = PaywallEvent.Data.random()
        let event: PaywallEvent = .purchaseInitiated(creationData, data)
        let map = event.toMap()

        expect(map["discriminator"] as? String) == "paywalls"
        expect(map["type"] as? String) == "paywall_purchase_initiated"
    }

    func testPaywallPurchaseErrorToMap() {
        let creationData = PaywallEvent.CreationData.random()
        let data = PaywallEvent.Data.random()
        let event: PaywallEvent = .purchaseError(creationData, data)
        let map = event.toMap()

        expect(map["discriminator"] as? String) == "paywalls"
        expect(map["type"] as? String) == "paywall_purchase_error"
    }

    // MARK: - toMap (Customer Center Events)

    func testCustomerCenterImpressionToMap() {
        let creationData = CustomerCenterEventCreationData()
        let data = CustomerCenterEvent.Data(
            locale: Locale(identifier: "en_US"),
            darkMode: true,
            isSandbox: false,
            displayMode: .fullScreen
        )
        let event: CustomerCenterEvent = .impression(creationData, data)
        let map = (event as FeatureEvent).toMap()

        expect(map["discriminator"] as? String) == "customer_center"
        expect(map["type"] as? String) == "customer_center_impression"
        expect(map["id"] as? String) == creationData.id.uuidString
        expect(map["timestamp"] as? UInt64) == creationData.date.millisecondsSince1970
        expect(map["dark_mode"] as? Bool) == true
        expect(map["locale"] as? String) == "en_US"
        expect(map["display_mode"] as? String) == "full_screen"
    }

    func testCustomerCenterAnswerSubmittedToMap() {
        let creationData = CustomerCenterEventCreationData()
        let data = CustomerCenterAnswerSubmittedEvent.Data(
            locale: Locale(identifier: "es_ES"),
            darkMode: false,
            isSandbox: true,
            displayMode: .sheet,
            path: .cancel,
            url: URL(string: "https://example.com"),
            surveyOptionID: "option_1",
            revisionID: 42
        )
        let event: CustomerCenterAnswerSubmittedEvent = .answerSubmitted(creationData, data)
        let map = (event as FeatureEvent).toMap()

        expect(map["discriminator"] as? String) == "customer_center"
        expect(map["type"] as? String) == "customer_center_survey_option_chosen"
        expect(map["id"] as? String) == creationData.id.uuidString
        expect(map["timestamp"] as? UInt64) == creationData.date.millisecondsSince1970
        expect(map["dark_mode"] as? Bool) == false
        expect(map["locale"] as? String) == "es_ES"
        expect(map["display_mode"] as? String) == "sheet"
        expect(map["survey_option_id"] as? String) == "option_1"
        expect(map["path"] as? String) == "CANCEL"
        expect(map["revision_id"] as? Int) == 42
        expect(map["url"] as? String) == "https://example.com"
    }

    func testCustomerCenterAnswerSubmittedToMapWithNilUrl() {
        let creationData = CustomerCenterEventCreationData()
        let data = CustomerCenterAnswerSubmittedEvent.Data(
            locale: Locale(identifier: "en_US"),
            darkMode: true,
            isSandbox: false,
            displayMode: .fullScreen,
            path: .refundRequest,
            url: nil,
            surveyOptionID: "option_2",
            revisionID: 1
        )
        let event: CustomerCenterAnswerSubmittedEvent = .answerSubmitted(creationData, data)
        let map = (event as FeatureEvent).toMap()

        expect(map["url"]).to(beNil())
        expect(map["survey_option_id"] as? String) == "option_2"
        expect(map["path"] as? String) == "REFUND_REQUEST"
    }

    // MARK: - flushAllEvents

    func testFlushEmptyStore() async throws {
        let result = try await self.manager.flushAllEvents(batchSize: 1)
        expect(result) == 0
        expect(self.api.invokedPostPaywallEvents) == false
    }

    func testFlushOneEvent() async throws {
        let event = await self.storeRandomEvent()

        let result = try await self.manager.flushAllEvents(batchSize: 1)
        expect(result) == 1

        expect(self.api.invokedPostPaywallEvents) == true
        expect(self.api.invokedPostPaywallEventsParameters) == [[try createStoredFeatureEvent(from: event)]]

        await self.verifyEmptyStore()
    }

    func testFlushTwice() async throws {
        let event1 = await self.storeRandomEvent()
        let event2 = await self.storeRandomEvent()

        let result1 = try await self.manager.flushAllEvents(batchSize: 1)
        let result2 = try await self.manager.flushAllEvents(batchSize: 1)

        expect(result1) == 2
        expect(result2) == 0

        expect(self.api.invokedPostPaywallEvents) == true
        expect(self.api.invokedPostPaywallEventsParameters) == [
            [try createStoredFeatureEvent(from: event1)],
            [try createStoredFeatureEvent(from: event2)]
        ]

        await self.verifyEmptyStore()
    }

    func testFlushAllEventsInBatches() async throws {
        let event1 = await self.storeRandomEvent()
        let event2 = await self.storeRandomEvent()
        let event3 = await self.storeRandomEvent()

        let result = try await self.manager.flushAllEvents(batchSize: 1)
        expect(result) == 3

        expect(self.api.invokedPostPaywallEvents) == true
        expect(self.api.invokedPostPaywallEventsParameters) == [
            [try createStoredFeatureEvent(from: event1)],
            [try createStoredFeatureEvent(from: event2)],
            [try createStoredFeatureEvent(from: event3)]
        ]

        await self.verifyEmptyStore()
    }

    func testFlushMultipleEventsInLargerBatches() async throws {
        let event1 = await self.storeRandomEvent()
        let event2 = await self.storeRandomEvent()
        let event3 = await self.storeRandomEvent()
        let event4 = await self.storeRandomEvent()
        let event5 = await self.storeRandomEvent()

        let result = try await self.manager.flushAllEvents(batchSize: 2)
        expect(result) == 5

        expect(self.api.invokedPostPaywallEvents) == true
        expect(self.api.invokedPostPaywallEventsParameters) == [
            [try createStoredFeatureEvent(from: event1), try createStoredFeatureEvent(from: event2)],
            [try createStoredFeatureEvent(from: event3), try createStoredFeatureEvent(from: event4)],
            [try createStoredFeatureEvent(from: event5)]
        ]

        await self.verifyEmptyStore()
    }

    func testFlushWithUnsuccessfulPostError() async throws {
        let event = await self.storeRandomEvent()
        let storedEvent = try createStoredFeatureEvent(from: event)
        let expectedError: NetworkError = .offlineConnection()

        self.api.stubbedPostPaywallEventsCompletionResult = .networkError(expectedError)
        do {
            _ = try await self.manager.flushAllEvents(batchSize: 1)
            fail("Expected error")
        } catch BackendError.networkError(expectedError) {
            // Expected
        } catch {
            throw error
        }

        expect(self.api.invokedPostPaywallEvents) == true
        expect(self.api.invokedPostPaywallEventsParameters) == [[storedEvent]]

        await self.verifyEvents([storedEvent])
    }

    func testFlushWithSuccessfullySyncedError() async throws {
        _ = await self.storeRandomEvent()

        self.api.stubbedPostPaywallEventsCompletionResult = .networkError(
            .errorResponse(.defaultResponse, .invalidRequest)
        )

        let result = try await self.manager.flushAllEvents(batchSize: 1)

        expect(result) == 1
        expect(self.api.invokedPostPaywallEvents) == true

        await self.verifyEmptyStore()
    }

    func testFlushWithSuccessfullySyncedErrorContinuesToNextBatch() async throws {
        let event1 = await self.storeRandomEvent()
        let event2 = await self.storeRandomEvent()

        self.api.stubbedPostPaywallEventsCompletionResult = .networkError(
            .errorResponse(.defaultResponse, .invalidRequest)
        )

        let result = try await self.manager.flushAllEvents(batchSize: 1)

        expect(result) == 2
        expect(self.api.invokedPostPaywallEvents) == true
        expect(self.api.invokedPostPaywallEventsParameters) == [
            [try createStoredFeatureEvent(from: event1)],
            [try createStoredFeatureEvent(from: event2)]
        ]

        await self.verifyEmptyStore()
    }

    func testFlushWithUnsuccessfulPostErrorStopsAfterFirstBatch() async throws {
        let event1 = await self.storeRandomEvent()
        let event2 = await self.storeRandomEvent()
        let expectedError: NetworkError = .offlineConnection()

        self.api.stubbedPostPaywallEventsCompletionResult = .networkError(expectedError)

        do {
            _ = try await self.manager.flushAllEvents(batchSize: 1)
            fail("Expected error")
        } catch BackendError.networkError(expectedError) {
            // Expected
        } catch {
            throw error
        }

        expect(self.api.invokedPostPaywallEvents) == true
        expect(self.api.invokedPostPaywallEventsParameters) == [
            [try createStoredFeatureEvent(from: event1)]
        ]

        // Both events should still be in the store since the first batch failed
        await self.verifyEvents([
            try createStoredFeatureEvent(from: event1),
            try createStoredFeatureEvent(from: event2)
        ])
    }

    func testFlushLimitsToMaxBatchesPerFlush() async throws {
        // Store 15 batches worth of events (batch size = 2, so 30 events)
        let eventsPerBatch = 2
        let totalBatches = 15
        let totalEvents = eventsPerBatch * totalBatches

        var storedEvents: [PaywallEvent] = []
        for _ in 0..<totalEvents {
            let event = await self.storeRandomEvent()
            storedEvents.append(event)
        }

        // Flush with batch size 2, should only send 10 batches (20 events)
        let result = try await self.manager.flushAllEvents(batchSize: eventsPerBatch)
        let expectedEventsFlushed = eventsPerBatch * EventsManager.maxBatchesPerFlush
        expect(result) == expectedEventsFlushed

        // Verify exactly 10 batches were sent
        expect(self.api.invokedPostPaywallEventsParameters).to(haveCount(EventsManager.maxBatchesPerFlush))

        // Verify the first 10 batches match expected events
        for batchIndex in 0..<EventsManager.maxBatchesPerFlush {
            let batchStartIndex = batchIndex * eventsPerBatch
            let batchEndIndex = batchStartIndex + eventsPerBatch
            let expectedBatch = try storedEvents[batchStartIndex..<batchEndIndex].map {
                try createStoredFeatureEvent(from: $0)
            }
            expect(self.api.invokedPostPaywallEventsParameters[batchIndex]) == expectedBatch
        }

        // Verify remaining events are still in store
        let remainingEvents = await self.store.storedEvents
        let expectedRemainingCount = totalEvents - expectedEventsFlushed
        expect(remainingEvents).to(haveCount(expectedRemainingCount))
    }

    #if swift(>=5.9)
    @available(iOS 16.0, macOS 13.0, tvOS 16.0, watchOS 9.0, *)
    func testCannotFlushMultipleTimesInParallel() async throws {
        // The way this test is written does not work in iOS 15.
        // The second Task does not start until the first one is done.
        try AvailabilityChecks.iOS16APIAvailableOrSkipTest()

        let event1 = await self.storeRandomEvent()
        _ = await self.storeRandomEvent()

        // Creates a stream and its continuation
        let continuation = AsyncStream<Void>.makeStream()

        // Set up the mock to wait for our signal
        self.api.stubbedPostPaywallEventsCallback = { completion in
            Task {
                // This waits until something is sent through the stream
                await continuation.stream.first { _ in true }
                // Once we receive the signal, call completion
                completion(nil)
            }
        }

        let manager = self.manager!
        async let result1 = manager.flushAllEvents(batchSize: 1)
        async let result2 = manager.flushAllEvents(batchSize: 1)

        // Signal the API call to complete
        continuation.continuation.yield()
        continuation.continuation.finish()

        // Wait for both results
        let results = try await [result1, result2]
        expect(Set(results)) == [2, 0]

        expect(self.api.invokedPostPaywallEvents) == true
        expect(self.api.invokedPostPaywallEventsParameters).to(haveCount(2))
        expect(self.api.invokedPostPaywallEventsParameters.first) == [
            try createStoredFeatureEvent(from: event1)
        ]

        self.logger.verifyMessageWasLogged(
            Strings.paywalls.event_flush_already_in_progress,
            level: .debug,
            expectedCount: 1
        )
    }
    #endif

    // MARK: - flushAllEvents with ad events

    func testFlushAllEventsFlushesFeatureAndAdEvents() async throws {
        self.createManagerWithAdEvents()

        // Store feature events
        let featureEvent1: PaywallEvent = .impression(.random(), .random())
        let featureEvent2: PaywallEvent = .close(.random(), .random())
        await self.manager.track(featureEvent: featureEvent1)
        await self.manager.track(featureEvent: featureEvent2)

        // Store ad events
        let adEvent1: AdEvent = .randomDisplayedEvent()
        let adEvent2: AdEvent = .randomDisplayedEvent()
        await self.manager.track(adEvent: adEvent1)
        await self.manager.track(adEvent: adEvent2)

        let result = try await self.manager.flushAllEvents(batchSize: 10)

        // Should have flushed both types
        expect(result) == 4

        // Both stores should be empty
        await self.verifyEmptyStore()
        expect(self.api.invokedPostPaywallEvents) == true
        expect(self.api.invokedPostAdEvents) == true
    }

    func testFlushAllEventsReturnsZeroWhenBothStoresEmpty() async throws {
        self.createManagerWithAdEvents()

        let result = try await self.manager.flushAllEvents(batchSize: 1)
        expect(result) == 0
    }

    func testFlushAllEventsOnlyFlushesFeatureEventsWhenAdStoreEmpty() async throws {
        self.createManagerWithAdEvents()

        let featureEvent: PaywallEvent = .impression(.random(), .random())
        await self.manager.track(featureEvent: featureEvent)

        let result = try await self.manager.flushAllEvents(batchSize: 10)

        expect(result) == 1

        let featureEvents = await self.store.storedEvents
        expect(featureEvents).to(beEmpty())
        expect(self.api.invokedPostPaywallEvents) == true
        expect(self.api.invokedPostAdEvents) == false
    }

    func testFlushAllEventsOnlyFlushesAdEventsWhenFeatureStoreEmpty() async throws {
        self.createManagerWithAdEvents()

        let adEvent1: AdEvent = .randomDisplayedEvent()
        let adEvent2: AdEvent = .randomDisplayedEvent()
        await self.manager.track(adEvent: adEvent1)
        await self.manager.track(adEvent: adEvent2)

        let result = try await self.manager.flushAllEvents(batchSize: 10)

        expect(result) == 2

        await self.verifyEmptyStore()
        expect(self.api.invokedPostPaywallEvents) == false
        expect(self.api.invokedPostAdEvents) == true
    }

    func testFlushAllEventsThrowsIfFeatureEventsFlushFails() async throws {
        self.createManagerWithAdEvents()

        let featureEvent: PaywallEvent = .impression(.random(), .random())
        await self.manager.track(featureEvent: featureEvent)

        let adEvent: AdEvent = .randomDisplayedEvent()
        await self.manager.track(adEvent: adEvent)

        let expectedError: NetworkError = .offlineConnection()
        self.api.stubbedPostPaywallEventsCompletionResult = .networkError(expectedError)

        do {
            _ = try await self.manager.flushAllEvents(batchSize: 10)
            fail("Expected error")
        } catch BackendError.networkError(expectedError) {
            // Expected
        } catch {
            throw error
        }

        // Feature event should still be in store
        let featureEvents = await self.store.storedEvents
        expect(featureEvents).to(haveCount(1))

        // Ad events API should not have been called (not flushed if feature flush failed)
        expect(self.api.invokedPostAdEvents) == false
    }

    func testFlushAllEventsThrowsIfAdEventsFlushFails() async throws {
        self.createManagerWithAdEvents()

        let featureEvent: PaywallEvent = .impression(.random(), .random())
        await self.manager.track(featureEvent: featureEvent)

        let adEvent: AdEvent = .randomDisplayedEvent()
        await self.manager.track(adEvent: adEvent)

        let expectedError: NetworkError = .offlineConnection()
        self.api.stubbedPostAdEventsCompletionResult = .networkError(expectedError)

        do {
            _ = try await self.manager.flushAllEvents(batchSize: 10)
            fail("Expected error")
        } catch BackendError.networkError(expectedError) {
            // Expected
        } catch {
            throw error
        }

        // Feature event should be flushed (succeeded first)
        let featureEvents = await self.store.storedEvents
        expect(featureEvents).to(beEmpty())

        // Ad events should have been attempted
        expect(self.api.invokedPostAdEvents) == true
    }

    // MARK: -

    private static let userID = "nacho"

}

// MARK: - Private

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private extension EventsManagerTests {

    func storeRandomEvent() async -> PaywallEvent {
        let event: PaywallEvent = .impression(.random(), .random())
        await self.manager.track(featureEvent: event)

        return event
    }

    func verifyEmptyStore(file: FileString = #filePath, line: UInt = #line) async {
        let events = await self.store.storedEvents
        expect(file: file, line: line, events).to(beEmpty())
    }

    func verifyEvents(
        _ expected: [StoredFeatureEvent],
        file: FileString = #filePath,
        line: UInt = #line
    ) async {
        let events = await self.store.storedEvents
        expect(file: file, line: line, events) == expected
    }

    func createStoredFeatureEvent(from event: PaywallEvent) throws -> StoredFeatureEvent {
        return try XCTUnwrap(.init(event: event,
                                   userID: Self.userID,
                                   feature: .paywalls,
                                   appSessionID: self.appSessionID,
                                   eventDiscriminator: nil))
    }

}

// MARK: - MockFeatureEventStore

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private actor MockFeatureEventStore: FeatureEventStoreType {

    var storedEvents: [StoredFeatureEvent] = []

    func store(_ storedEvent: StoredFeatureEvent) {
        self.storedEvents.append(storedEvent)
    }

    func fetch(_ count: Int) -> [StoredFeatureEvent] {
        return Array(self.storedEvents.prefix(count))
    }

    func clear(_ count: Int) {
        self.storedEvents.removeFirst(min(count, self.storedEvents.count))
    }

}

// MARK: - MockAdEventStore

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
private actor MockAdEventStore: AdEventStoreType {

    var storedEvents: [StoredAdEvent] = []

    func store(_ storedEvent: StoredAdEvent) {
        self.storedEvents.append(storedEvent)
    }

    func fetch(_ count: Int) -> [StoredAdEvent] {
        return Array(self.storedEvents.prefix(count))
    }

    func clear(_ count: Int) {
        self.storedEvents.removeFirst(min(count, self.storedEvents.count))
    }

}
