//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
// Created by RevenueCat on 3/01/20.
//

import XCTest
import Nimble

@testable import Purchases
@testable import PurchasesCoreSwift

class PurchasesSubscriberAttributesTests: XCTestCase {

    var mockReceiptFetcher: MockReceiptFetcher!
    let mockRequestFetcher = MockRequestFetcher()
    let mockProductsManager = MockProductsManager()
    let mockBackend = MockBackend()
    let mockStoreKitWrapper = MockStoreKitWrapper()
    let mockNotificationCenter = MockNotificationCenter()
    var userDefaults: UserDefaults! = nil
    let mockOfferingsFactory = MockOfferingsFactory()
    var mockDeviceCache: MockDeviceCache!
    let mockIdentityManager = MockIdentityManager(mockAppUserID: "app_user");
    let mockSubscriberAttributesManager = MockSubscriberAttributesManager()
    var subscriberAttributeHeight: SubscriberAttribute!
    var subscriberAttributeWeight: SubscriberAttribute!
    var mockAttributes: [String: SubscriberAttribute]!
    let systemInfo: SystemInfo = try! MockSystemInfo(platformFlavor: nil,
                                                     platformFlavorVersion: nil,
                                                     finishTransactions: true)
    var mockReceiptParser: MockReceiptParser!
    var mockAttributionFetcher: MockAttributionFetcher!
    var mockAttributionPoster: RCAttributionPoster!

    var mockOperationDispatcher: MockOperationDispatcher!
    var mockIntroEligibilityCalculator: MockIntroEligibilityCalculator!

    let purchasesDelegate = MockPurchasesDelegate()
    var purchaserInfoManager: PurchaserInfoManager!
    let emptyPurchaserInfoData: [String: Any] = [
    "request_date": "2019-08-16T10:30:42Z",
    "subscriber": [
        "first_seen": "2019-07-17T00:05:54Z",
        "original_app_user_id": "",
        "subscriptions": [:],
        "other_purchases": [:],
        "original_application_version": NSNull()
    ]]

    var purchases: Purchases!

    override func setUp() {
        userDefaults = UserDefaults(suiteName: "TestDefaults")
        self.mockDeviceCache = MockDeviceCache(userDefaults: userDefaults)

        self.subscriberAttributeHeight = SubscriberAttribute(withKey: "height",
                                                             value: "183")
        self.subscriberAttributeWeight = SubscriberAttribute(withKey: "weight",
                                                             value: "160")
        self.mockAttributes = [
            subscriberAttributeHeight.key: subscriberAttributeHeight,
            subscriberAttributeWeight.key: subscriberAttributeWeight
        ]
        self.mockOperationDispatcher = MockOperationDispatcher()
        self.mockIntroEligibilityCalculator = MockIntroEligibilityCalculator()
        self.mockReceiptParser = MockReceiptParser()
        let systemInfoAttribution = try! MockSystemInfo(platformFlavor: "iOS",
                                                        platformFlavorVersion: "3.2.1",
                                                        finishTransactions: true)
        self.mockAttributionFetcher = MockAttributionFetcher(attributionFactory: AttributionTypeFactory(),
                                                             systemInfo: systemInfoAttribution)
        self.mockAttributionPoster = RCAttributionPoster(deviceCache: mockDeviceCache,
                                                         identityManager: mockIdentityManager,
                                                         backend: mockBackend,
                                                         systemInfo: systemInfoAttribution,
                                                         attributionFetcher: mockAttributionFetcher,
                                                         subscriberAttributesManager: mockSubscriberAttributesManager)
        self.purchaserInfoManager = PurchaserInfoManager(operationDispatcher: mockOperationDispatcher,
                                                         deviceCache: mockDeviceCache,
                                                         backend: mockBackend,
                                                         systemInfo: systemInfo)
        self.mockReceiptFetcher = MockReceiptFetcher(requestFetcher: mockRequestFetcher)

    }

    override func tearDown() {
        purchases?.delegate = nil
        purchases = nil
        Purchases.setDefaultInstance(nil)
        UserDefaults().removePersistentDomain(forName: "TestDefaults")
    }

    func setupPurchases(automaticCollection: Bool = false) {
        Purchases.automaticAppleSearchAdsAttributionCollection = automaticCollection
        self.mockIdentityManager.mockIsAnonymous = false
        purchases = Purchases(appUserID: mockIdentityManager.currentAppUserID,
                              requestFetcher: mockRequestFetcher,
                              receiptFetcher: mockReceiptFetcher,
                              attributionFetcher: mockAttributionFetcher,
                              attributionPoster: mockAttributionPoster,
                              backend: mockBackend,
                              storeKitWrapper: mockStoreKitWrapper,
                              notificationCenter: mockNotificationCenter,
                              systemInfo: systemInfo,
                              offeringsFactory: mockOfferingsFactory,
                              deviceCache: mockDeviceCache,
                              identityManager: mockIdentityManager,
                              subscriberAttributesManager: mockSubscriberAttributesManager,
                              operationDispatcher: mockOperationDispatcher,
                              introEligibilityCalculator: mockIntroEligibilityCalculator,
                              receiptParser: mockReceiptParser,
                              purchaserInfoManager: purchaserInfoManager,
                              productsManager: mockProductsManager)
        purchases!.delegate = purchasesDelegate
        Purchases.setDefaultInstance(purchases!)
    }

    func testInitializerConfiguresSubscriberAttributesManager() {
        let purchases = Purchases.configure(withAPIKey: "key")
        expect(purchases.subscriberAttributesManager).toNot(beNil())
    }

    // Mark: Notifications

    func testSubscribesToForegroundNotifications() {
        setupPurchases()

        expect(self.mockNotificationCenter.observers.count) > 0

        var isObservingDidBecomeActive = false

        for (_, _, name, _) in self.mockNotificationCenter.observers {
            if name == UIApplication.didBecomeActiveNotification {
                isObservingDidBecomeActive = true
                break
            }
        }
        expect(isObservingDidBecomeActive) == true

        self.mockNotificationCenter.fireNotifications()
        expect(self.mockSubscriberAttributesManager.invokedSyncAttributesForAllUsersCount) == 2
    }

    func testSubscribesToBackgroundNotifications() {
        setupPurchases()

        expect(self.mockNotificationCenter.observers.count) > 0

        var isObservingDidBecomeActive = false

        for (_, _, name, _) in self.mockNotificationCenter.observers {
            if name == UIApplication.willResignActiveNotification {
                isObservingDidBecomeActive = true
                break
            }
        }
        expect(isObservingDidBecomeActive) == true

        self.mockNotificationCenter.fireNotifications()
        expect(self.mockSubscriberAttributesManager.invokedSyncAttributesForAllUsersCount) == 2
    }

    func testSubscriberAttributesSyncIsPerformedAfterPurchaserInfoSync() {
        mockBackend.stubbedGetSubscriberDataPurchaserInfo = PurchaserInfo(data: [
            "request_date": "2019-08-16T10:30:42Z",
            "subscriber": [
                "first_seen": "2019-07-17T00:05:54Z",
                "original_app_user_id": "app_user_id",
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "1.0",
                "original_purchase_date": "2018-10-26T23:17:53Z"
            ]
        ])

        setupPurchases()

        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
        expect(self.mockDeviceCache.cachePurchaserInfoCount) == 1
        expect(self.mockDeviceCache.cachedPurchaserInfo.count) == 1
        expect(self.mockSubscriberAttributesManager.invokedSyncAttributesForAllUsersCount) == 0

        self.mockNotificationCenter.fireNotifications()

        expect(self.mockSubscriberAttributesManager.invokedSyncAttributesForAllUsersCount) == 2
        expect(self.mockDeviceCache.cachePurchaserInfoCount) == 1
        expect(self.mockDeviceCache.cachedPurchaserInfo.count) == 1
    }

    // Mark: Set attributes

    func testSetAttributesMakesRightCalls() {
        setupPurchases()

        Purchases.shared.setAttributes(["genre": "rock n' roll"])
        expect(self.mockSubscriberAttributesManager.invokedSetAttributesCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetAttributesParameters?.attributes) == ["genre": "rock n' roll"]
        expect(self.mockSubscriberAttributesManager.invokedSetAttributesParameters?.appUserID) == mockIdentityManager.currentAppUserID
    }

    func testSetEmailMakesRightCalls() {
        setupPurchases()

        Purchases.shared.setEmail("ac.dc@rock.com")
        expect(self.mockSubscriberAttributesManager.invokedSetEmailCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetEmailParameters?.email) == "ac.dc@rock.com"
        expect(self.mockSubscriberAttributesManager.invokedSetEmailParameters?.appUserID) == mockIdentityManager
            .currentAppUserID
    }

    func testSetPhoneNumberMakesRightCalls() {
        setupPurchases()

        Purchases.shared.setPhoneNumber("8561365841")
        expect(self.mockSubscriberAttributesManager.invokedSetPhoneNumberCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetPhoneNumberParameters?.phoneNumber) == "8561365841"
        expect(self.mockSubscriberAttributesManager.invokedSetPhoneNumberParameters?.appUserID) == mockIdentityManager
            .currentAppUserID
    }

    func testSetDisplayNameMakesRightCalls() {
        setupPurchases()

        Purchases.shared.setDisplayName("Stevie Ray Vaughan")
        expect(self.mockSubscriberAttributesManager.invokedSetDisplayNameCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetDisplayNameParameters?.displayName) == "Stevie Ray Vaughan"
        expect(self.mockSubscriberAttributesManager.invokedSetDisplayNameParameters?.appUserID) == mockIdentityManager
            .currentAppUserID
    }

    func testSetPushTokenMakesRightCalls() {
        setupPurchases()
        let tokenData = Data("ligai32g32ig".data(using: .utf8)!)
        let tokenString = (tokenData as NSData).rc_asString()

        Purchases.shared.setPushToken(tokenData)
        expect(self.mockSubscriberAttributesManager.invokedSetPushTokenCount) == 1

        let receivedPushToken = self.mockSubscriberAttributesManager.invokedSetPushTokenParameters!.pushToken!

        expect((receivedPushToken as NSData).rc_asString()) == tokenString
        expect(self.mockSubscriberAttributesManager.invokedSetPushTokenParameters?.appUserID) == mockIdentityManager
            .currentAppUserID
    }

    func testSetPushTokenStringMakesRightCalls() {
        setupPurchases()
        let tokenString = "ligai32g32ig"

        Purchases.shared._setPushTokenString(tokenString)
        expect(self.mockSubscriberAttributesManager.invokedSetPushTokenStringCount) == 1

        let receivedPushToken = self.mockSubscriberAttributesManager.invokedSetPushTokenStringParameters!.pushToken!

        expect(receivedPushToken) == tokenString
        expect(self.mockSubscriberAttributesManager.invokedSetPushTokenStringParameters?.appUserID) ==
            mockIdentityManager.currentAppUserID
    }

    func testSetAdjustIDMakesRightCalls() {
        setupPurchases()

        Purchases.shared.setAdjustID("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetAdjustIDCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetAdjustIDParameters?.adjustID) == "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetAdjustIDParameters?.appUserID) == mockIdentityManager
                .currentAppUserID
    }

    func testSetAppsflyerIDMakesRightCalls() {
        setupPurchases()

        Purchases.shared.setAppsflyerID("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetAppsflyerIDCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetAppsflyerIDParameters?.appsflyerID) == "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetAppsflyerIDParameters?.appUserID) == mockIdentityManager
                .currentAppUserID
    }

    func testSetFBAnonymousIDMakesRightCalls() {
        setupPurchases()

        Purchases.shared.setFBAnonymousID("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetFBAnonymousIDCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetFBAnonymousIDParameters?.fbAnonymousID) == "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetFBAnonymousIDParameters?.appUserID) == mockIdentityManager
                .currentAppUserID
    }

    func testSetMparticleIDMakesRightCalls() {
        setupPurchases()

        Purchases.shared.setMparticleID("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetMparticleIDCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetMparticleIDParameters?.mparticleID) == "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetMparticleIDParameters?.appUserID) == mockIdentityManager
                .currentAppUserID
    }

    func testSetOnesignalIDMakesRightCalls() {
        setupPurchases()

        Purchases.shared.setOnesignalID("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetOnesignalIDCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetOnesignalIDParameters?.onesignalID) == "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetOnesignalIDParameters?.appUserID) == mockIdentityManager
                .currentAppUserID
    }

    func testSetMediaSourceMakesRightCalls() {
        setupPurchases()

        Purchases.shared.setMediaSource("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetMediaSourceCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetMediaSourceParameters?.mediaSource) == "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetMediaSourceParameters?.appUserID) == mockIdentityManager
                .currentAppUserID
    }

    func testSetCampaignMakesRightCalls() {
        setupPurchases()

        Purchases.shared.setCampaign("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetCampaignCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetCampaignParameters?.campaign) == "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetCampaignParameters?.appUserID) == mockIdentityManager
                .currentAppUserID
    }

    func testSetAdGroupMakesRightCalls() {
        setupPurchases()

        Purchases.shared.setAdGroup("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetAdGroupCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetAdGroupParameters?.adGroup) == "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetAdGroupParameters?.appUserID) == mockIdentityManager
                .currentAppUserID
    }

    func testSetAdMakesRightCalls() {
        setupPurchases()

        Purchases.shared.setAd("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetAdCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetAdParameters?.ad) == "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetAdParameters?.appUserID) == mockIdentityManager
                .currentAppUserID
    }

    func testSetKeywordMakesRightCalls() {
        setupPurchases()

        Purchases.shared.setKeyword("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetKeywordCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetKeywordParameters?.keyword) == "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetKeywordParameters?.appUserID) == mockIdentityManager
                .currentAppUserID
    }

    func testSetCreativeMakesRightCalls() {
        setupPurchases()

        Purchases.shared.setCreative("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetCreativeCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetCreativeParameters?.creative) == "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetCreativeParameters?.appUserID) == mockIdentityManager
                .currentAppUserID
    }

    func testCollectDeviceIdentifiersMakesRightCalls() {
        setupPurchases()

        Purchases.shared.collectDeviceIdentifiers()
        expect(self.mockSubscriberAttributesManager.invokedCollectDeviceIdentifiersCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedCollectDeviceIdentifiersParameters?.appUserID) == mockIdentityManager
                .currentAppUserID
    }

    // MARK: Post receipt with attributes

    func testPostReceiptMarksSubscriberAttributesSyncedIfBackendSuccessful() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in }
        mockSubscriberAttributesManager.stubbedUnsyncedAttributesByKeyResult = mockAttributes

        let transaction = MockTransaction()
        transaction.mockPayment = self.mockStoreKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.mockStoreKitWrapper.delegate?.storeKitWrapper(self.mockStoreKitWrapper, updatedTransaction: transaction)

        self.mockBackend.stubbedPostReceiptPurchaserInfo = PurchaserInfo(data: emptyPurchaserInfoData)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.mockStoreKitWrapper.delegate?.storeKitWrapper(self.mockStoreKitWrapper, updatedTransaction: transaction)

        expect(self.mockBackend.invokedPostReceiptData).to(beTrue())
        expect(self.mockStoreKitWrapper.finishCalled).toEventually(beTrue())
        expect(self.mockSubscriberAttributesManager.invokedMarkAttributes) == true
        expect(self.mockSubscriberAttributesManager.invokedMarkAttributesParameters!.syncedAttributes) == mockAttributes
        expect(self.mockSubscriberAttributesManager.invokedMarkAttributesParameters!.appUserID) == mockIdentityManager
            .currentAppUserID
    }

    func testPostReceiptMarksSubscriberAttributesSyncedIfBackendSuccessfullySynced() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in }
        mockSubscriberAttributesManager.stubbedUnsyncedAttributesByKeyResult = mockAttributes

        let transaction = MockTransaction()
        transaction.mockPayment = self.mockStoreKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.mockStoreKitWrapper.delegate?.storeKitWrapper(self.mockStoreKitWrapper, updatedTransaction: transaction)

        let errorCode = BackendErrorCode.invalidAPIKey.rawValue as NSNumber
        let extraUserInfo = [Backend.RCSuccessfullySyncedKey: true]
        self.mockBackend.stubbedPostReceiptPurchaserError = ErrorUtils.backendError(withBackendCode: errorCode,
                                                                                              backendMessage: "Invalid credentials",
                                                                                              extraUserInfo: extraUserInfo)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.mockStoreKitWrapper.delegate?.storeKitWrapper(self.mockStoreKitWrapper, updatedTransaction: transaction)

        expect(self.mockBackend.invokedPostReceiptData) == true
        expect(self.mockSubscriberAttributesManager.invokedMarkAttributes) == true
        expect(self.mockSubscriberAttributesManager.invokedMarkAttributesParameters!.syncedAttributes) == mockAttributes
        expect(self.mockSubscriberAttributesManager.invokedMarkAttributesParameters!.appUserID) == mockIdentityManager
            .currentAppUserID
    }

    func testPostReceiptDoesntMarkSubscriberAttributesSyncedIfBackendNotSuccessfullySynced() {
        setupPurchases()
        let product = MockSKProduct(mockProductIdentifier: "com.product.id1")
        self.purchases?.purchaseProduct(product) { (tx, info, error, userCancelled) in }
        mockSubscriberAttributesManager.stubbedUnsyncedAttributesByKeyResult = mockAttributes

        let transaction = MockTransaction()
        transaction.mockPayment = self.mockStoreKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.mockStoreKitWrapper.delegate?.storeKitWrapper(self.mockStoreKitWrapper, updatedTransaction: transaction)

        let errorCode = BackendErrorCode.invalidAPIKey.rawValue as NSNumber
        let extraUserInfo = [Backend.RCSuccessfullySyncedKey as NSError.UserInfoKey: false]
        self.mockBackend.stubbedPostReceiptPurchaserError = ErrorUtils.backendError(withBackendCode: errorCode,
                                                                                              backendMessage: "Invalid credentials",
                                                                                              extraUserInfo: extraUserInfo)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.mockStoreKitWrapper.delegate?.storeKitWrapper(self.mockStoreKitWrapper, updatedTransaction: transaction)

        expect(self.mockBackend.invokedPostReceiptData).to(beTrue())
        expect(self.mockSubscriberAttributesManager.invokedMarkAttributes) == false
    }
}
