//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DiagnosticsTrackerTests.swift
//
//  Created by Cesar de la Vega on 11/4/24.

import Foundation
import Nimble

@testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class DiagnosticsTrackerTests: TestCase {

    fileprivate var fileHandler: FileHandler!
    fileprivate var handler: DiagnosticsFileHandler!
    fileprivate var tracker: DiagnosticsTracker!
    fileprivate var diagnosticsDispatcher: MockOperationDispatcher!
    fileprivate var dateProvider: MockDateProvider!

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.fileHandler = try Self.createWithTemporaryFile()
        self.handler = .init(self.fileHandler)
        self.diagnosticsDispatcher = MockOperationDispatcher()
        self.dateProvider = .init(stubbedNow: Self.eventTimestamp1, subsequentNows: Self.eventTimestamp2)
        self.tracker = .init(diagnosticsFileHandler: self.handler,
                             diagnosticsDispatcher: self.diagnosticsDispatcher,
                             dateProvider: self.dateProvider)
    }

    override func tearDown() async throws {
        self.handler = nil

        try await super.tearDown()
    }

    // MARK: - trackEvent

    func testTrackEvent() async {
        let appSessionId = SystemInfo.appSessionID
        let event = DiagnosticsEvent(name: .httpRequestPerformed,
                                     properties: DiagnosticsEvent.Properties(verificationResult: "FAILED"),
                                     timestamp: Self.eventTimestamp1,
                                     appSessionId: appSessionId)

        self.tracker.track(event)

        let entries = await self.handler.getEntries()
        expect(entries) == [
            .init(id: event.id,
                  name: .httpRequestPerformed,
                  properties: DiagnosticsEvent.Properties(verificationResult: "FAILED"),
                  timestamp: Self.eventTimestamp1,
                  appSessionId: appSessionId)
        ]
    }

    func testTrackMultipleEvents() async {
        let appSessionId = SystemInfo.appSessionID
        let event1 = DiagnosticsEvent(name: .httpRequestPerformed,
                                      properties: DiagnosticsEvent.Properties(verificationResult: "FAILED"),
                                      timestamp: Self.eventTimestamp1,
                                      appSessionId: appSessionId)
        let event2 = DiagnosticsEvent(name: .customerInfoVerificationResult,
                                      properties: DiagnosticsEvent.Properties(verificationResult: "FAILED"),
                                      timestamp: Self.eventTimestamp2,
                                      appSessionId: appSessionId)

        self.tracker.track(event1)
        self.tracker.track(event2)

        let entries = await self.handler.getEntries()
        Self.expectEventArrayWithoutId(entries, [
            .init(id: event1.id,
                  name: .httpRequestPerformed,
                  properties: DiagnosticsEvent.Properties(verificationResult: "FAILED"),
                  timestamp: Self.eventTimestamp1,
                  appSessionId: appSessionId),
            .init(id: event1.id,
                  name: .customerInfoVerificationResult,
                  properties: DiagnosticsEvent.Properties(verificationResult: "FAILED"),
                  timestamp: Self.eventTimestamp2,
                  appSessionId: appSessionId)
        ])
    }

    // MARK: - customer info verification

    func testDoesNotTrackWhenVerificationIsNotRequested() async {
        let customerInfo: CustomerInfo = .emptyInfo.copy(with: .notRequested)

        self.tracker.trackCustomerInfoVerificationResultIfNeeded(customerInfo)

        let entries = await self.handler.getEntries()
        expect(entries.count) == 0
    }

    func testTracksCustomerInfoVerificationFailed() async {
        let customerInfo: CustomerInfo = .emptyInfo.copy(with: .failed)

        self.tracker.trackCustomerInfoVerificationResultIfNeeded(customerInfo)

        let entries = await self.handler.getEntries()
        expect(entries.count) == 1
        Self.expectEventArrayWithoutId(entries, [
            .init(name: .customerInfoVerificationResult,
                  properties: DiagnosticsEvent.Properties(verificationResult: "FAILED"),
                  timestamp: Self.eventTimestamp1,
                  appSessionId: SystemInfo.appSessionID)
        ])
    }

    // MARK: - http request performed

    func testTracksHttpRequestPerformedWithExpectedParameters() async {
        self.tracker.trackHttpRequestPerformed(endpointName: "mock_endpoint",
                                               responseTime: 50,
                                               wasSuccessful: true,
                                               responseCode: 200,
                                               backendErrorCode: 7121,
                                               resultOrigin: .cache,
                                               verificationResult: .verified,
                                               isRetry: false)
        let entries = await self.handler.getEntries()
        Self.expectEventArrayWithoutId(entries, [
            .init(name: .httpRequestPerformed,
                  properties: DiagnosticsEvent.Properties(
                    verificationResult: "VERIFIED",
                    endpointName: "mock_endpoint",
                    responseTime: 50,
                    successful: true,
                    responseCode: 200,
                    backendErrorCode: 7121,
                    etagHit: true,
                    isRetry: false
                  ),
                  timestamp: Self.eventTimestamp1,
                  appSessionId: SystemInfo.appSessionID)
        ])
    }

    // MARK: - product request

    func testTracksProductRequestWithExpectedParameters() async {
        self.tracker.trackProductsRequest(wasSuccessful: false,
                                          storeKitVersion: .storeKit2,
                                          errorMessage: "test error message",
                                          errorCode: 1234,
                                          storeKitErrorDescription: "store_kit_error_type",
                                          requestedProductIds: ["test_product_id_1", "test_product_id_2"],
                                          notFoundProductIds: ["test_product_id_2"],
                                          responseTime: 50)
        let emptyErrorMessage: String? = nil
        let emptyErrorCode: Int? = nil
        let emptySkErrorDescription: String? = nil
        self.tracker.trackProductsRequest(wasSuccessful: true,
                                          storeKitVersion: .storeKit1,
                                          errorMessage: emptyErrorMessage,
                                          errorCode: emptyErrorCode,
                                          storeKitErrorDescription: emptySkErrorDescription,
                                          requestedProductIds: ["test_product_id_3", "test_product_id_4"],
                                          notFoundProductIds: [],
                                          responseTime: 20)

        let entries = await self.handler.getEntries()
        Self.expectEventArrayWithoutId(entries, [
            .init(name: .appleProductsRequest,
                  properties: DiagnosticsEvent.Properties(
                    responseTime: 50,
                    storeKitVersion: .storeKit2,
                    successful: false,
                    errorMessage: "test error message",
                    errorCode: 1234,
                    skErrorDescription: "store_kit_error_type",
                    requestedProductIds: ["test_product_id_1", "test_product_id_2"],
                    notFoundProductIds: ["test_product_id_2"]
                  ),
                  timestamp: Self.eventTimestamp1,
                  appSessionId: SystemInfo.appSessionID),
            .init(name: .appleProductsRequest,
                  properties: DiagnosticsEvent.Properties(
                    responseTime: 20,
                    storeKitVersion: .storeKit1,
                    successful: true,
                    errorMessage: emptyErrorMessage,
                    errorCode: emptyErrorCode,
                    skErrorDescription: emptySkErrorDescription,
                    requestedProductIds: ["test_product_id_3", "test_product_id_4"],
                    notFoundProductIds: []
                  ),
                  timestamp: Self.eventTimestamp2,
                  appSessionId: SystemInfo.appSessionID)
        ])
    }

    // MARK: - Purchase Request

    func testTracksPurchaseRequestWithExpectedParameters() async {
        self.tracker.trackPurchaseRequest(wasSuccessful: true,
                                          storeKitVersion: .storeKit2,
                                          errorMessage: nil,
                                          errorCode: nil,
                                          storeKitErrorDescription: nil,
                                          productId: "com.revenuecat.product1",
                                          promotionalOfferId: nil,
                                          winBackOfferApplied: false,
                                          purchaseResult: .verified,
                                          responseTime: 75)

        let emptyErrorMessage: String? = nil
        let emptyErrorCode: Int? = nil
        let emptyPromotionalOfferId: String? = nil
        let emptySkErrorDescription: String? = nil
        let entries = await self.handler.getEntries()
        Self.expectEventArrayWithoutId(entries, [
            .init(name: .applePurchaseAttempt,
                  properties: DiagnosticsEvent.Properties(
                    responseTime: 75,
                    storeKitVersion: .storeKit2,
                    successful: true,
                    errorMessage: emptyErrorMessage,
                    errorCode: emptyErrorCode,
                    skErrorDescription: emptySkErrorDescription,
                    productId: "com.revenuecat.product1",
                    promotionalOfferId: emptyPromotionalOfferId,
                    winBackOfferApplied: false,
                    purchaseResult: .verified
                  ),
                  timestamp: Self.eventTimestamp1,
                  appSessionId: SystemInfo.appSessionID)
        ])
    }

    func testTracksPurchaseRequestWithPromotionalOffer() async {
        self.tracker.trackPurchaseRequest(wasSuccessful: false,
                                          storeKitVersion: .storeKit1,
                                          errorMessage: "purchase failed",
                                          errorCode: 5678,
                                          storeKitErrorDescription: "payment_cancelled",
                                          productId: "com.revenuecat.premium",
                                          promotionalOfferId: "summer_discount_2023",
                                          winBackOfferApplied: true,
                                          purchaseResult: .userCancelled,
                                          responseTime: 120)

        let entries = await self.handler.getEntries()
        Self.expectEventArrayWithoutId(entries, [
            .init(name: .applePurchaseAttempt,
                  properties: DiagnosticsEvent.Properties(
                    responseTime: 120,
                    storeKitVersion: .storeKit1,
                    successful: false,
                    errorMessage: "purchase failed",
                    errorCode: 5678,
                    skErrorDescription: "payment_cancelled",
                    productId: "com.revenuecat.premium",
                    promotionalOfferId: "summer_discount_2023",
                    winBackOfferApplied: true,
                    purchaseResult: .userCancelled
                  ),
                  timestamp: Self.eventTimestamp1,
                  appSessionId: SystemInfo.appSessionID)
        ])
    }

    // MARK: - Offerings result

    func testTrackingOfferingsResult() async {
        let requestedProductIds: Set<String> = ["test-product-id-1", "test-product-id-2"]
        let notFoundProductIds: Set<String> = ["test-product-id-1"]
        self.tracker.trackOfferingsResult(requestedProductIds: requestedProductIds,
                                          notFoundProductIds: notFoundProductIds,
                                          errorMessage: nil,
                                          errorCode: nil,
                                          verificationResult: nil,
                                          cacheStatus: .notFound,
                                          responseTime: 1234)
        let entries = await self.handler.getEntries()
        Self.expectEventArrayWithoutId(entries, [
            .init(name: .getOfferingsResult,
                  properties: DiagnosticsEvent.Properties(
                    responseTime: 1234,
                    requestedProductIds: requestedProductIds,
                    notFoundProductIds: notFoundProductIds,
                    cacheStatus: .notFound
                  ),
                  timestamp: Self.eventTimestamp1,
                  appSessionId: SystemInfo.appSessionID)
        ])
    }

    // MARK: - empty diagnostics file when too big

    func testTrackingEventClearsDiagnosticsFileIfTooBig() async throws {
        for _ in 0...8000 {
            await self.handler.appendEvent(diagnosticsEvent: .init(name: .httpRequestPerformed,
                                                                   properties: .empty,
                                                                   timestamp: Date(),
                                                                   appSessionId: SystemInfo.appSessionID))
        }

        let entries = await self.handler.getEntries()
        expect(entries.count) == 8001

        let event = DiagnosticsEvent(name: .httpRequestPerformed,
                                     properties: DiagnosticsEvent.Properties(verificationResult: "FAILED"),
                                     timestamp: Self.eventTimestamp2,
                                     appSessionId: SystemInfo.appSessionID)

        self.tracker.track(event)

        let entries2 = await self.handler.getEntries()
        expect(entries2.count) == 2
        Self.expectEventArrayWithoutId(entries2, [
            .init(name: .maxEventsStoredLimitReached,
                  properties: .empty,
                  timestamp: Self.eventTimestamp1,
                  appSessionId: SystemInfo.appSessionID),
            .init(name: .httpRequestPerformed,
                  properties: DiagnosticsEvent.Properties(verificationResult: "FAILED"),
                  timestamp: Self.eventTimestamp2,
                  appSessionId: SystemInfo.appSessionID)
        ])
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension DiagnosticsTrackerTests {

    static let eventTimestamp1: Date = .init(timeIntervalSince1970: 1694029328)
    static let eventTimestamp2: Date = .init(timeIntervalSince1970: 1694022321)

    static func temporaryFileURL() -> URL {
        return FileManager.default
            .temporaryDirectory
            .appendingPathComponent("file_handler_tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: false)
            .appendingPathExtension("jsonl")
    }

    static func createWithTemporaryFile() throws -> FileHandler {
        return try FileHandler(Self.temporaryFileURL())
    }

    static func expectEventArrayWithoutId(_ obtained: [DiagnosticsEvent?], _ expected: [DiagnosticsEvent?]) {
        expect(obtained.count) == expected.count
        guard obtained.count == expected.count else {
            return
        }

        for (index, obtainedEvent) in obtained.enumerated() {
            let expectedEvent = expected[index]
            Self.expectEventWithoutId(obtainedEvent, expectedEvent)
        }
    }

    static func expectEventWithoutId(_ obtained: DiagnosticsEvent?, _ expected: DiagnosticsEvent?) {
        expect(obtained?.version) == expected?.version
        expect(obtained?.properties) == expected?.properties
        expect(obtained?.timestamp) == expected?.timestamp
        expect(obtained?.version) == expected?.version
        expect(obtained?.appSessionId) == expected?.appSessionId
    }
}
