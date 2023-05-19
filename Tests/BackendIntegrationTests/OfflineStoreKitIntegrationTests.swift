//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OfflineStoreKitIntegrationTests.swift
//
//  Created by Nacho Soto on 5/17/23.

import Nimble
@testable import RevenueCat
import StoreKit
import XCTest

// swiftlint:disable type_name

class BaseOfflineStoreKitIntegrationTests: BaseStoreKitIntegrationTests {

    fileprivate var serverIsDown: Bool = false
    override var forceServerErrors: Bool { return self.serverIsDown }

    override func setUp() async throws {
        self.serverIsDown = false
        try await super.setUp()

        await self.waitForPendingCustomerInfoRequests()
    }

}

class OfflineStoreKit2IntegrationTests: OfflineStoreKit1IntegrationTests {

    override class var storeKit2Setting: StoreKit2Setting { return .enabledForCompatibleDevices }

}

class OfflineStoreKit1IntegrationTests: BaseOfflineStoreKitIntegrationTests {

    override func setUp() async throws {
        try await super.setUp()

        if #available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *) {
            try await self.ensureEntitlementMappingIsAvailable()
        }
    }

    func testOfferingsAreCachedInMemory() async throws {
        let onlineOfferings = try await Purchases.shared.offerings()
        expect(onlineOfferings.all).toNot(beEmpty())

        self.serverDown()

        let offlineOfferings = try await Purchases.shared.offerings()
        expect(offlineOfferings) === onlineOfferings
    }

    func testOfferingsAreCachedOnDisk() async throws {
        let onlineOfferings = try await Purchases.shared.offerings()
        expect(onlineOfferings.all).toNot(beEmpty())

        self.serverDown()
        await self.resetSingleton()

        let offlineOfferings = try await Purchases.shared.offerings()
        expect(offlineOfferings.response) == onlineOfferings.response

        let offering = try XCTUnwrap(offlineOfferings.current)
        expect(offering.availablePackages.count) == onlineOfferings.current?.availablePackages.count
        expect(offering.monthly?.storeProduct.productIdentifier) == "com.revenuecat.monthly_4.99.1_week_intro"
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testOfflineCustomerInfoWithNoPurchases() async throws {
        Purchases.shared.invalidateCustomerInfoCache()

        self.serverDown()

        let info = try await Purchases.shared.customerInfo()
        expect(info.entitlements.all).to(beEmpty())
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testReturnsCachedCustomerInfo() async throws {
        let logger = TestLogHandler()

        self.serverDown()

       _ = try await Purchases.shared.customerInfo()

        logger.verifyMessageWasNotLogged(Strings.customerInfo.customerinfo_updated_offline)
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testOfflineCustomerInfoWithOnePurchase() async throws {
        try await self.purchaseMonthlyOffering()

        Purchases.shared.invalidateCustomerInfoCache()
        self.serverDown()

        let info = try await Purchases.shared.customerInfo()
        expect(info.entitlements.all).toNot(beEmpty())
        try await self.verifyEntitlementWentThrough(info)
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseWhileServerIsDownSucceedsButDoesNotFinishTransaction() async throws {
        let logger = TestLogHandler()

        self.serverDown()
        try await self.purchaseMonthlyProduct()

        logger.verifyMessageWasLogged(Strings.offlineEntitlements.computing_offline_customer_info, level: .info)
        logger.verifyMessageWasNotLogged("Finishing transaction")
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseWhileServerIsDownPostsReceiptAfterServerComesBack() async throws {
        let logger = TestLogHandler()

        // 1. Purchase while server is down
        self.serverDown()
        try await self.purchaseMonthlyProduct()

        logger.verifyMessageWasNotLogged("Finishing transaction")

        // 2. "Re-open" the app after the server is back
        self.serverUp()
        Purchases.shared.invalidateCustomerInfoCache()
        await self.resetSingleton()

        // 3. Ensure delegate is notified of subscription
        try await asyncWait(
            until: { [delegate = self.purchasesDelegate] in
                delegate?.customerInfo?.activeSubscriptions.isEmpty == false
            },
            timeout: .seconds(5),
            pollInterval: .milliseconds(200),
            description: "Subscription never became active"
        )

        // 4. Ensure transaction is eventually finished
        try await logger.verifyMessageIsEventuallyLogged(
            "Finishing transaction",
            level: .info,
            timeout: .seconds(5),
            pollInterval: .milliseconds(100)
        )

        // 5. Restart app again
        Purchases.shared.invalidateCustomerInfoCache()
        await self.resetSingleton()

        // 6. To ensure (with a clean cache) that the receipt was posted
        let info = try await Purchases.shared.customerInfo()
        try await self.verifyEntitlementWentThrough(info)
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testReopeningAppWithOfflineEntitlementsDoesNotReturnStaleCache() async throws {
        // 1. Purchase while server is down
        self.serverDown()
        try await self.purchaseMonthlyProduct()

        // 2. "Re-open" the app
        await self.resetSingleton()

        // 3. `CustomerInfo` should contain offline purchase
        let info = try await Purchases.shared.customerInfo()
        try await self.verifyEntitlementWentThrough(info)
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchaseAgainAfterServerRecovers() async throws {
        // 1. Purchase while server is down
        self.serverDown()
        try await self.purchaseMonthlyProduct()

        // 2. Purchase again when the server is back up
        // (maybe the app failed the first time?)
        self.serverUp()
        try await self.purchaseMonthlyProduct()

        // 3. `CustomerInfo` should contain the purchase
        let info = try await Purchases.shared.customerInfo()
        try await self.verifyEntitlementWentThrough(info)
        expect(info.activeSubscriptions).to(haveCount(1))
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchasingTwoProductsWhileServerIsDown() async throws {
        let product1 = try await self.monthlyPackage.storeProduct
        let product2 = try await self.annualPackage.storeProduct

        self.serverDown()

        _ = try await Purchases.shared.purchase(product: product1)
        let info = try await Purchases.shared.purchase(product: product2).customerInfo

        try await self.verifyEntitlementWentThrough(info)
        expect(info.allPurchasedProductIdentifiers) == [
            product1.productIdentifier,
            product2.productIdentifier
        ]
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testPurchasingSecondProductAfterServerIsUp() async throws {
        let product1 = try await self.monthlyPackage.storeProduct
        let product2 = try await self.annualPackage.storeProduct

        self.serverDown()

        _ = try await Purchases.shared.purchase(product: product1)

        self.serverUp()

        let info = try await Purchases.shared.purchase(product: product2).customerInfo

        try await self.verifyEntitlementWentThrough(info)
        expect(info.allPurchasedProductIdentifiers) == [
            product1.productIdentifier,
            product2.productIdentifier
        ]
    }

}

class OfflineWithNoMappingStoreKitIntegrationTests: BaseOfflineStoreKitIntegrationTests {

    override var forceServerErrors: Bool { return true }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testOfflineCustomerInfoFailsIfNoEntitlementMapping() async throws {
        let logger = TestLogHandler()

        Purchases.shared.invalidateCustomerInfoCache()

        do {
            _ = try await Purchases.shared.customerInfo(fetchPolicy: .fetchCurrent)
            fail("Fetch should have failed")
        } catch let error as ErrorCode {
            expect(error).to(matchError(ErrorCode.unknownBackendError))
        } catch let error {
            fail("Unexpected error: \(error)")
        }

        logger.verifyMessageWasLogged(
            Strings.offlineEntitlements.computing_offline_customer_info_with_no_entitlement_mapping
        )
    }

}

// MARK: -

private extension BaseOfflineStoreKitIntegrationTests {

    final func serverDown() { self.serverIsDown = true }
    final func serverUp() { self.serverIsDown = false }

    func waitForPendingCustomerInfoRequests() async {
        _ = try? await Purchases.shared.customerInfo()
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func ensureEntitlementMappingIsAvailable() async throws {
        _ = try await Purchases.shared.productEntitlementMapping()
    }

}
