//
// Created by RevenueCat on 3/01/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import XCTest
import OHHTTPStubs
import Nimble

import Purchases

class PurchasesSubscriberAttributesTests: XCTestCase {

    let mockReceiptFetcher = MockReceiptFetcher()
    let mockRequestFetcher = MockRequestFetcher()
    let mockBackend = MockBackend()
    let mockStoreKitWrapper = MockStoreKitWrapper()
    let mockNotificationCenter = MockNotificationCenter()
    var userDefaults: UserDefaults! = nil
    let mockAttributionFetcher = MockAttributionFetcher()
    let mockOfferingsFactory = MockOfferingsFactory()
    let mockDeviceCache = MockDeviceCache()
    let mockIdentityManager = MockUserManager(mockAppUserID: "app_user");
    let mockSubscriberAttributesManager = MockSubscriberAttributesManager()
    var subscriberAttributeHeight: RCSubscriberAttribute!
    var subscriberAttributeWeight: RCSubscriberAttribute!
    var mockAttributes: [String: RCSubscriberAttribute]!

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
                              observerMode: false,
                              offeringsFactory: mockOfferingsFactory,
                              deviceCache: mockDeviceCache,
                              identityManager: mockIdentityManager,
                              subscriberAttributesManager: mockSubscriberAttributesManager)
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
        expect(self.mockSubscriberAttributesManager.invokedSyncIfNeededCount) == 2
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
        expect(self.mockSubscriberAttributesManager.invokedSyncIfNeededCount) == 2
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

    // MARK: Post receipt with attributes

    func testPostReceiptMarksSubscriberAttributesSyncedIfBackendSuccessful() {
        setupPurchases()
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
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
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
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
        let product = MockProduct(mockProductIdentifier: "com.product.id1")
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
