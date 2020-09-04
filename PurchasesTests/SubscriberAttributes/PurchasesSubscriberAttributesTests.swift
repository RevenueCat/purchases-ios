//
// Created by RevenueCat on 3/01/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import XCTest
import Nimble

@testable import Purchases

class PurchasesSubscriberAttributesTests: XCTestCase {

    let mockReceiptFetcher = MockReceiptFetcher()
    let mockRequestFetcher = MockRequestFetcher()
    let mockBackend = MockBackend()
    let mockStoreKitWrapper = MockStoreKitWrapper()
    let mockNotificationCenter = MockNotificationCenter()
    var userDefaults: UserDefaults! = nil
    let mockOfferingsFactory = MockOfferingsFactory()
    let mockDeviceCache = MockDeviceCache()
    let mockIdentityManager = MockIdentityManager(mockAppUserID: "app_user");
    let mockSubscriberAttributesManager = MockSubscriberAttributesManager()
    var subscriberAttributeHeight: RCSubscriberAttribute!
    var subscriberAttributeWeight: RCSubscriberAttribute!
    var mockAttributes: [String: RCSubscriberAttribute]!
    let systemInfo: RCSystemInfo = MockSystemInfo(platformFlavor: nil,
                                                  platformFlavorVersion: nil,
                                                  finishTransactions: true)
    var mockReceiptParser: MockReceiptParser!
    var mockAttributionFetcher: MockAttributionFetcher!

    var mockOperationDispatcher: MockOperationDispatcher!
    var mockIntroEligibilityCalculator: MockIntroEligibilityCalculator!

    let purchasesDelegate = MockPurchasesDelegate()

    var purchases: Purchases!

    override func setUp() {
        self.userDefaults = UserDefaults(suiteName: "TestDefaults")
        self.subscriberAttributeHeight = RCSubscriberAttribute(key: "height",
                                                               value: "183")
        self.subscriberAttributeWeight = RCSubscriberAttribute(key: "weight",
                                                               value: "160")
        self.mockAttributes = [
            subscriberAttributeHeight.key: subscriberAttributeHeight,
            subscriberAttributeWeight.key: subscriberAttributeWeight
        ]
        self.mockOperationDispatcher = MockOperationDispatcher()
        self.mockIntroEligibilityCalculator = MockIntroEligibilityCalculator()
        self.mockReceiptParser = MockReceiptParser()
        self.mockAttributionFetcher = MockAttributionFetcher(deviceCache: mockDeviceCache,
                                                             identityManager: mockIdentityManager)
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
                              backend: mockBackend,
                              storeKitWrapper: mockStoreKitWrapper,
                              notificationCenter: mockNotificationCenter,
                              userDefaults: userDefaults,
                              systemInfo: systemInfo,
                              offeringsFactory: mockOfferingsFactory,
                              deviceCache: mockDeviceCache,
                              identityManager: mockIdentityManager,
                              subscriberAttributesManager: mockSubscriberAttributesManager,
                              operationDispatcher: mockOperationDispatcher,
                              introEligibilityCalculator: mockIntroEligibilityCalculator,
                              receiptParser: mockReceiptParser)
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
        mockBackend.stubbedGetSubscriberDataPurchaserInfo = Purchases.PurchaserInfo(data: [
            "subscriber": [
                "subscriptions": [:],
                "other_purchases": [:],
                "original_application_version": "1.0",
                "original_purchase_date": "2018-10-26T23:17:53Z"
            ]
        ])

        setupPurchases()

        expect(self.mockOperationDispatcher.invokedDispatchOnWorkerThreadCount) == 1
        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSyncAttributesForAllUsersCount) == 0
        expect(self.mockDeviceCache.cachedPurchaserInfo.count) == 1

        self.mockNotificationCenter.fireNotifications()

        expect(self.mockOperationDispatcher.invokedDispatchOnWorkerThreadCount) == 3
        expect(self.mockSubscriberAttributesManager.invokedSyncAttributesForAllUsersCount) == 2
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
        let tokenString = (tokenData as NSData).asString()

        Purchases.shared.setPushToken(tokenData)
        expect(self.mockSubscriberAttributesManager.invokedSetPushTokenCount) == 1

        let receivedPushToken = self.mockSubscriberAttributesManager.invokedSetPushTokenParameters!.pushToken!

        expect((receivedPushToken as NSData).asString()) == tokenString
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

        self.mockBackend.stubbedPostReceiptPurchaserInfo = Purchases.PurchaserInfo()

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

        let errorCode = Purchases.RevenueCatBackendErrorCode.invalidAPIKey.rawValue as NSNumber
        let extraUserInfo = [RCSuccessfullySyncedKey: true]
        self.mockBackend.stubbedPostReceiptPurchaserError = Purchases.ErrorUtils.backendError(withBackendCode: errorCode,
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

        let errorCode = Purchases.RevenueCatBackendErrorCode.invalidAPIKey.rawValue as NSNumber
        let extraUserInfo = [RCSuccessfullySyncedKey: false]
        self.mockBackend.stubbedPostReceiptPurchaserError = Purchases.ErrorUtils.backendError(withBackendCode: errorCode,
                                                                                              backendMessage: "Invalid credentials",
                                                                                              extraUserInfo: extraUserInfo)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.mockStoreKitWrapper.delegate?.storeKitWrapper(self.mockStoreKitWrapper, updatedTransaction: transaction)

        expect(self.mockBackend.invokedPostReceiptData).to(beTrue())
        expect(self.mockSubscriberAttributesManager.invokedMarkAttributes) == false
    }
}
