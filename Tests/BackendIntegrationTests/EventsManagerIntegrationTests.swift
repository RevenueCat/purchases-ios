//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EventsManagerIntegrationTests.swift
//
//  Created by Facundo Menzella on 26/2/25.

import Nimble
import XCTest

#if ENABLE_CUSTOM_ENTITLEMENT_COMPUTATION
@_spi(Internal) @testable import RevenueCat_CustomEntitlementComputation
#else
@_spi(Internal) @testable import RevenueCat
#endif

@MainActor
final class EventsManagerIntegrationTests: BaseBackendIntegrationTests {

    // Use a real EventsManager directly so tests can await event storage before flushing.
    // Purchases.track(customerCenterEvent:) schedules background work and returns immediately.
    private var eventsManager: EventsManager!

    override func setUp() async throws {
        try await super.setUp()

        let systemInfo = SystemInfo(
            platformInfo: nil,
            finishTransactions: true,
            storeKitVersion: Self.storeKitVersion,
            apiKey: self.apiKey,
            responseVerificationMode: Self.responseVerificationMode,
            dangerousSettings: DangerousSettings(autoSyncPurchases: true, internalSettings: self),
            isAppBackgrounded: false,
            preferredLocalesProvider: PreferredLocalesProvider(preferredLocaleOverride: nil)
        )
        let backend = Backend(
            systemInfo: systemInfo,
            eTagManager: ETagManager(),
            tokenManager: TokenManager(enabled: false, storage: Keychain(access: nil)),
            operationDispatcher: .default,
            attributionFetcher: AttributionFetcher(
                attributionFactory: AttributionTypeFactory(),
                systemInfo: systemInfo
            ),
            offlineCustomerInfoCreator: nil,
            diagnosticsTracker: nil,
            apiSourceProvider: nil,
            timeoutManager: HTTPRequestTimeoutManager(networkTimeout: .default)
        )
        let storeURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try FeatureEventStore(handler: FileHandler(storeURL))
        self.eventsManager = EventsManager(
            internalAPI: backend.internalAPI,
            userProvider: EventUserProvider(currentAppUserID: try self.purchases.appUserID),
            store: store,
            systemInfo: systemInfo
        )
        self.addTeardownBlock {
            self.eventsManager = nil
            try FileManager.default.removeItem(at: storeURL)
        }
    }

    func testPostingPaywallsDoesNotFail() async throws {
        let events = [
            PaywallEvent.cancel(
                Self.eventCreationData, Self.eventData
            ),
            PaywallEvent.close(
                Self.eventCreationData, Self.eventData
            ),
            PaywallEvent.cancel(
                Self.eventCreationData, Self.eventData
            )
        ]

        for event in events {
            await self.eventsManager.track(
                featureEvent: event
            )
        }

        try await flushAndVerify(eventsCount: events.count)
    }

    func testPostingCustomerCenterDoesNotFail() async throws {
        let locale = Locale(identifier: "es_ES")
        await self.eventsManager.track(
            featureEvent: CustomerCenterEvent.impression(
                Self.customerCenterCreationData,
                CustomerCenterEvent.Data(
                    locale: locale,
                    darkMode: true,
                    isSandbox: true,
                    displayMode: .fullScreen
                )
            )
        )

        await self.eventsManager.track(
            featureEvent: CustomerCenterAnswerSubmittedEvent.answerSubmitted(
                Self.customerCenterCreationData,
                CustomerCenterAnswerSubmittedEvent.Data(
                    locale: locale,
                    darkMode: true,
                    isSandbox: true,
                    displayMode: .fullScreen,
                    path: .cancel,
                    url: nil,
                    surveyOptionID: "",
                    revisionID: 1
                )
            )
        )
        try await flushAndVerify(eventsCount: 2)
    }

    private func flushAndVerify(eventsCount: Int) async throws {
        _ = try await self.eventsManager.flushFeatureEvents(batchSize: eventsCount)

        let logger = try XCTUnwrap(self.logger)
        try await asyncWait(
            timeout: .seconds(10),
            description: { _ in "Expected all \(eventsCount) events to be posted successfully" },
            until: { logger.messages },
            condition: { messages in
                let batchSizes = messages.compactMap { entry in
                    (1...eventsCount).first { count in
                        entry.message.contains(Strings.paywalls.event_flush_starting(count: count).description)
                    }
                }
                let successfulBatches = messages.filter {
                    $0.level == .debug && $0.message.contains(Strings.analytics.flush_events_success.description)
                }.count
                return batchSizes.reduce(0, +) == eventsCount && successfulBatches == batchSizes.count
            }
        )
    }

    static let customerCenterCreationData: CustomerCenterEventCreationData = .init(
        id: .init(uuidString: "72164C05-2BDC-4807-8918-A4105F727DEB")!,
        date: .init(timeIntervalSince1970: 1694029328)
    )

    static let eventCreationData: PaywallEvent.CreationData = .init(
        id: .init(uuidString: "72164C05-2BDC-4807-8918-A4105F727DEB")!,
        date: .init(timeIntervalSince1970: 1694029328)
    )

    static let eventData: PaywallEvent.Data = .init(
        paywallIdentifier: "test_paywall_id",
        offeringIdentifier: "offering",
        paywallRevision: 0,
        sessionID: .init(uuidString: "98CC0F1D-7665-4093-9624-1D7308FFF4DB")!,
        displayMode: .fullScreen,
        localeIdentifier: "es_ES",
        darkMode: true,
        source: nil
    )
}

private final class EventUserProvider: CurrentUserProvider {

    let currentAppUserID: String
    let currentUserIsAnonymous = true

    init(currentAppUserID: String) {
        self.currentAppUserID = currentAppUserID
    }

}
