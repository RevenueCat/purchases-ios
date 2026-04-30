//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesCustomPaywallEventsTests.swift
//
//  Created by Rick van der Linden.

import Nimble
import StoreKit
import XCTest

@_spi(Internal) @testable import RevenueCat

@available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *)
class PurchasesCustomPaywallEventsTests: BasePurchasesTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        self.setupPurchases()
    }

    func testTrackCustomPaywallImpressionWithPaywallId() async throws {
        self.setupMockOfferingsWithCurrentOffering(identifier: "test_offering")

        let params = CustomPaywallImpressionParams(paywallId: "my_paywall")
        self.purchases.trackCustomPaywallImpression(params)

        let manager = try self.mockEventsManager

        await expect { await manager.trackedEvents }.toEventually(haveCount(1))

        let trackedEvents = await manager.trackedEvents

        guard case let .impression(_, data) = trackedEvents.first as? CustomPaywallEvent else {
            fail("Expected CustomPaywallEvent.impression but got \(String(describing: trackedEvents.first))")
            return
        }

        expect(data.paywallId) == "my_paywall"
        expect(data.offeringId) == "test_offering"
    }

    func testTrackCustomPaywallImpressionWithoutParams() async throws {
        self.purchases.trackCustomPaywallImpression()

        let manager = try self.mockEventsManager

        await expect { await manager.trackedEvents }.toEventually(haveCount(1))

        let trackedEvents = await manager.trackedEvents

        guard case let .impression(_, data) = trackedEvents.first as? CustomPaywallEvent else {
            fail("Expected CustomPaywallEvent.impression but got \(String(describing: trackedEvents.first))")
            return
        }

        expect(data.paywallId).to(beNil())
    }

    func testTrackCustomPaywallImpressionWithNilPaywallId() async throws {
        let params = CustomPaywallImpressionParams(paywallId: nil)
        self.purchases.trackCustomPaywallImpression(params)

        let manager = try self.mockEventsManager

        await expect { await manager.trackedEvents }.toEventually(haveCount(1))

        let trackedEvents = await manager.trackedEvents

        guard case let .impression(_, data) = trackedEvents.first as? CustomPaywallEvent else {
            fail("Expected CustomPaywallEvent.impression but got \(String(describing: trackedEvents.first))")
            return
        }

        expect(data.paywallId).to(beNil())
    }

    func testTrackCustomPaywallImpressionIncludesOfferingId() async throws {
        self.setupMockOfferingsWithCurrentOffering(identifier: "my_offering")

        let params = CustomPaywallImpressionParams(paywallId: "pw")
        self.purchases.trackCustomPaywallImpression(params)

        let manager = try self.mockEventsManager

        await expect { await manager.trackedEvents }.toEventually(haveCount(1))

        let trackedEvents = await manager.trackedEvents

        guard case let .impression(_, data) = trackedEvents.first as? CustomPaywallEvent else {
            fail("Expected CustomPaywallEvent.impression but got \(String(describing: trackedEvents.first))")
            return
        }

        expect(data.offeringId) == "my_offering"
    }

    func testTrackCustomPaywallImpressionUsesOverriddenOfferingId() async throws {
        self.setupMockOfferingsWithCurrentOffering(identifier: "cached_offering")

        let params = CustomPaywallImpressionParams(paywallId: "pw", offeringId: "custom_offering")
        self.purchases.trackCustomPaywallImpression(params)

        let manager = try self.mockEventsManager

        await expect { await manager.trackedEvents }.toEventually(haveCount(1))

        let trackedEvents = await manager.trackedEvents

        guard case let .impression(_, data) = trackedEvents.first as? CustomPaywallEvent else {
            fail("Expected CustomPaywallEvent.impression but got \(String(describing: trackedEvents.first))")
            return
        }

        expect(data.offeringId) == "custom_offering"
    }

    func testTrackCustomPaywallImpressionOfferingIdIsNilWhenNoCachedOfferings() async throws {
        self.purchases.trackCustomPaywallImpression(CustomPaywallImpressionParams(paywallId: "pw"))

        let manager = try self.mockEventsManager

        await expect { await manager.trackedEvents }.toEventually(haveCount(1))

        let trackedEvents = await manager.trackedEvents

        guard case let .impression(_, data) = trackedEvents.first as? CustomPaywallEvent else {
            fail("Expected CustomPaywallEvent.impression but got \(String(describing: trackedEvents.first))")
            return
        }

        expect(data.offeringId).to(beNil())
    }

    func testTrackMultipleImpressionsInQuickSuccession() async throws {
        let paywallIds = ["paywall_1", "paywall_2", "paywall_3"]
        for id in paywallIds {
            self.purchases.trackCustomPaywallImpression(CustomPaywallImpressionParams(paywallId: id))
        }

        let manager = try self.mockEventsManager

        await expect { await manager.trackedEvents }.toEventually(haveCount(3))

        let trackedEvents = await manager.trackedEvents
        let trackedPaywallIds = trackedEvents.compactMap { event -> String? in
            guard case let .impression(_, data) = event as? CustomPaywallEvent else { return nil }
            return data.paywallId
        }

        expect(Set(trackedPaywallIds)) == Set(paywallIds)
    }

    // MARK: - Presented offering context resolution

    func testTrackCustomPaywallImpressionDerivesContextFromCachedCurrentOffering() async throws {
        let context = PresentedOfferingContext(
            offeringIdentifier: "current_offering",
            placementIdentifier: "home_banner",
            targetingContext: .init(revision: 3, ruleId: "rule_abc123")
        )
        self.setupMockOfferingsWithCurrentOffering(
            identifier: "current_offering",
            presentedOfferingContext: context
        )

        self.purchases.trackCustomPaywallImpression(CustomPaywallImpressionParams(paywallId: "pw"))

        let data = try await self.firstTrackedCustomPaywallEventData()

        expect(data.offeringId) == "current_offering"
        expect(data.placementIdentifier) == "home_banner"
        expect(data.targetingRevision) == 3
        expect(data.targetingRuleId) == "rule_abc123"
    }

    func testTrackCustomPaywallImpressionDoesNotInferContextWhenOfferingIdStringPassed() async throws {
        let context = PresentedOfferingContext(
            offeringIdentifier: "current_offering",
            placementIdentifier: "home_banner",
            targetingContext: .init(revision: 3, ruleId: "rule_abc123")
        )
        self.setupMockOfferingsWithCurrentOffering(
            identifier: "current_offering",
            presentedOfferingContext: context
        )

        let params = CustomPaywallImpressionParams(paywallId: "pw", offeringId: "explicit_offering")
        self.purchases.trackCustomPaywallImpression(params)

        let data = try await self.firstTrackedCustomPaywallEventData()

        expect(data.offeringId) == "explicit_offering"
        expect(data.placementIdentifier).to(beNil())
        expect(data.targetingRevision).to(beNil())
        expect(data.targetingRuleId).to(beNil())
    }

    func testTrackCustomPaywallImpressionUsesPassedOfferingContext() async throws {
        let cachedContext = PresentedOfferingContext(
            offeringIdentifier: "current_offering",
            placementIdentifier: "cached_placement",
            targetingContext: .init(revision: 1, ruleId: "cached_rule")
        )
        self.setupMockOfferingsWithCurrentOffering(
            identifier: "current_offering",
            presentedOfferingContext: cachedContext
        )

        let passedContext = PresentedOfferingContext(
            offeringIdentifier: "passed_offering",
            placementIdentifier: "passed_placement",
            targetingContext: .init(revision: 7, ruleId: "passed_rule")
        )
        let passedOffering = Self.makeOffering(
            identifier: "passed_offering",
            presentedOfferingContext: passedContext
        )

        self.purchases.trackCustomPaywallImpression(
            CustomPaywallImpressionParams(paywallId: "pw", offering: passedOffering)
        )

        let data = try await self.firstTrackedCustomPaywallEventData()

        expect(data.offeringId) == "passed_offering"
        expect(data.placementIdentifier) == "passed_placement"
        expect(data.targetingRevision) == 7
        expect(data.targetingRuleId) == "passed_rule"
    }

    func testTrackCustomPaywallImpressionLeavesContextNilWhenCachedOfferingHasNoContext() async throws {
        self.setupMockOfferingsWithCurrentOffering(identifier: "current_offering")

        self.purchases.trackCustomPaywallImpression(CustomPaywallImpressionParams(paywallId: "pw"))

        let data = try await self.firstTrackedCustomPaywallEventData()

        expect(data.offeringId) == "current_offering"
        expect(data.placementIdentifier).to(beNil())
        expect(data.targetingRevision).to(beNil())
        expect(data.targetingRuleId).to(beNil())
    }

    // MARK: - Helpers

    private func firstTrackedCustomPaywallEventData() async throws -> CustomPaywallEvent.Data {
        let manager = try self.mockEventsManager
        await expect { await manager.trackedEvents }.toEventually(haveCount(1))

        let trackedEvents = await manager.trackedEvents
        guard case let .impression(_, data) = trackedEvents.first as? CustomPaywallEvent else {
            throw NSError(domain: "PurchasesCustomPaywallEventsTests", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Expected CustomPaywallEvent.impression"
            ])
        }
        return data
    }

    private func setupMockOfferingsWithCurrentOffering(
        identifier: String,
        presentedOfferingContext: PresentedOfferingContext? = nil
    ) {
        let offering: Offering
        if let presentedOfferingContext = presentedOfferingContext {
            offering = Self.makeOffering(
                identifier: identifier,
                presentedOfferingContext: presentedOfferingContext
            )
        } else {
            offering = Offering(
                identifier: identifier,
                serverDescription: "Test offering",
                availablePackages: [],
                webCheckoutUrl: nil
            )
        }
        let offerings = Offerings(
            offerings: [identifier: offering],
            currentOfferingID: identifier,
            placements: nil,
            targeting: nil,
            contents: .mockContents,
            loadedFromDiskCache: false
        )
        self.mockOfferingsManager.stubbedOfferingsCompletionResult = .success(offerings)
    }

    private static func makeOffering(
        identifier: String,
        presentedOfferingContext: PresentedOfferingContext
    ) -> Offering {
        let package = Package(
            identifier: "$rc_monthly",
            packageType: .monthly,
            storeProduct: StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "monthly_product")),
            presentedOfferingContext: presentedOfferingContext,
            webCheckoutUrl: nil
        )
        return Offering(
            identifier: identifier,
            serverDescription: "",
            availablePackages: [package],
            webCheckoutUrl: nil
        )
    }

}
