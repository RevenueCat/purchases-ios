//
// Created by RevenueCat on 3/01/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import XCTest
import OHHTTPStubs
import Nimble

import Purchases

class PurchasesSubscriberAttributesTests: XCTestCase {

    override func setUp() {
        self.userDefaults = UserDefaults(suiteName: "TestDefaults")
    }

    override func tearDown() {
        purchases?.delegate = nil
        purchases = nil
        Purchases.setDefaultInstance(nil)
        UserDefaults().removePersistentDomain(forName: "TestDefaults")
    }

    let receiptFetcher = MockReceiptFetcher()
    let requestFetcher = MockRequestFetcher()
    let backend = MockBackend()
    let storeKitWrapper = MockStoreKitWrapper()
    let notificationCenter = MockNotificationCenter()
    var userDefaults: UserDefaults! = nil
    let attributionFetcher = MockAttributionFetcher()
    let offeringsFactory = MockOfferingsFactory()
    let deviceCache = MockDeviceCache()
    let identityManager = MockUserManager(mockAppUserID: "app_user");

    let purchasesDelegate = MockPurchasesDelegate()

    var purchases: Purchases!

    func setupPurchases(automaticCollection: Bool = false) {
        Purchases.automaticAppleSearchAdsAttributionCollection = automaticCollection
        self.identityManager.mockIsAnonymous = false
        purchases = Purchases(appUserID: identityManager.currentAppUserID,
                              requestFetcher: requestFetcher,
                              receiptFetcher: receiptFetcher,
                              attributionFetcher: attributionFetcher,
                              backend: backend,
                              storeKitWrapper: storeKitWrapper,
                              notificationCenter: notificationCenter,
                              userDefaults: userDefaults,
                              observerMode: false,
                              offeringsFactory: offeringsFactory,
                              deviceCache: deviceCache,
                              identityManager: identityManager)
        purchases!.delegate = purchasesDelegate
        Purchases.setDefaultInstance(purchases!)
    }

    func testInitializerConfiguresSubscriberAttributesManager() {
        let purchases = Purchases.configure(withAPIKey: "key")
        expect(purchases.subscriberAttributesManager).toNot(beNil())
    }

}
