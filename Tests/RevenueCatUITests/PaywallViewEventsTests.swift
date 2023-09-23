//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallViewEventsTests.swift
//
//  Created by Nacho Soto on 9/7/23.

import Nimble
import RevenueCat
@testable import RevenueCatUI
import SwiftUI
import XCTest

#if !os(watchOS) && !os(macOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
class PaywallViewEventsTests: TestCase {

    private var events: [PaywallEvent] = []
    private var handler: PurchaseHandler!

    private let mode: PaywallViewMode = .random
    private let scheme: ColorScheme = Bool.random() ? .dark : .light

    private var impressionEventExpectation: XCTestExpectation!
    private var closeEventExpectation: XCTestExpectation!
    private var cancelEventExpectation: XCTestExpectation!

    override func setUp() {
        super.setUp()

        self.handler =
            .cancelling()
            .map { _ in
                return { [weak self] event in
                    await self?.track(event)
                }
            }

        self.impressionEventExpectation = .init(description: "Impression event")
        self.closeEventExpectation = .init(description: "Close event")
        self.cancelEventExpectation = .init(description: "Cancel event")
    }

    func testPaywallImpressionEvent() async throws {
        let expectation = XCTestExpectation()

        try self.createView()
        .onAppear { expectation.fulfill() }
        .addToHierarchy()

        await self.fulfillment(of: [expectation], timeout: 1)

        expect(self.events).to(containElementSatisfying { $0.eventType == .impression })

        let event = try XCTUnwrap(self.events.first { $0.eventType == .impression })
        self.verifyEventData(event.data)
    }

    func testPaywallCloseEvent() async throws {
        try self.createView()
            .addToHierarchy()

        await self.fulfillment(of: [self.closeEventExpectation], timeout: 1)

        expect(self.events).to(haveCount(2))
        expect(self.events).to(containElementSatisfying { $0.eventType == .close })

        let event = try XCTUnwrap(self.events.first { $0.eventType == .impression })
        self.verifyEventData(event.data)
    }

    func testCloseEventHasSameSessionID() async throws {
        try self.createView()
            .addToHierarchy()

        await self.fulfillment(of: [self.closeEventExpectation], timeout: 1)

        expect(self.events).to(haveCount(2))
        expect(self.events.map(\.eventType)) == [.impression, .close]
        expect(Set(self.events.map(\.data.sessionIdentifier))).to(haveCount(1))
    }

    func testCancelledPurchase() async throws {
        try self.createView()
            .addToHierarchy()

        _ = try await self.handler.purchase(package: try XCTUnwrap(Self.offering.monthly))

        await self.fulfillment(of: [self.cancelEventExpectation, self.closeEventExpectation],
                               timeout: 1)

        expect(self.events).to(haveCount(3))
        expect(self.events.map(\.eventType)).to(contain([.impression, .cancel, .close]))
        expect(Set(self.events.map(\.data.sessionIdentifier))).to(haveCount(1))

        let data = try XCTUnwrap(self.events.first { $0.eventType == .cancel }).data
        self.verifyEventData(data)
    }

    func testDifferentPaywallsCreateSeparateSessionIdentifiers() async throws {
        self.impressionEventExpectation.expectedFulfillmentCount = 2
        self.closeEventExpectation.expectedFulfillmentCount = 2

        let firstCloseExpectation = XCTestExpectation(description: "First paywall was closed")

        try self.createView()
            .onDisappear { firstCloseExpectation.fulfill() }
            .addToHierarchy()

        await self.fulfillment(of: [firstCloseExpectation], timeout: 1)

        try self.createView()
            .addToHierarchy()

        await self.fulfillment(of: [self.impressionEventExpectation, self.closeEventExpectation], timeout: 1)

        expect(self.events).to(haveCount(4))
        expect(self.events.map(\.eventType)) == [.impression, .close, .impression, .close]
        expect(Set(self.events.map(\.data.sessionIdentifier))).to(haveCount(2))
    }

    private static let offering = TestData.offeringWithNoIntroOffer

}

// MARK: -

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private extension PaywallViewEventsTests {

    func track(_ event: PaywallEvent) {
        self.events.append(event)

        switch event {
        case .impression: self.impressionEventExpectation.fulfill()
        case .cancel: self.cancelEventExpectation.fulfill()
        case .close: self.closeEventExpectation.fulfill()
        }
    }

    func createView() -> some View {
        PaywallView(
            offering: Self.offering.withLocalImages,
            customerInfo: TestData.customerInfo,
            mode: self.mode,
            introEligibility: .producing(eligibility: .eligible),
            purchaseHandler: self.handler
        )
        .environment(\.colorScheme, self.scheme)
    }

    func verifyEventData(_ data: PaywallEvent.Data) {
        expect(data.offeringIdentifier) == Self.offering.identifier
        expect(data.paywallRevision) == Self.offering.paywall?.revision
        expect(data.displayMode) == self.mode
        expect(data.localeIdentifier) == Locale.current.identifier
        expect(data.darkMode) == (self.scheme == .dark)
    }

}

private extension PaywallViewMode {

    static var random: Self {
        return Self.allCases.randomElement()!
    }

}

private extension PaywallEvent {

    enum EventType {

        case impression
        case cancel
        case close

    }

    var eventType: EventType {
        switch self {
        case .impression: return .impression
        case .cancel: return .cancel
        case .close: return .close
        }
    }

}

#endif
