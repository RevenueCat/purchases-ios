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

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class PurchasesSubscriberAttributesTests: TestCase {

    var mockReceiptFetcher: MockReceiptFetcher!
    let mockRequestFetcher = MockRequestFetcher()
    var mockProductsManager: MockProductsManager!
    let mockBackend = MockBackend()
    let mockStoreKitWrapper = MockStoreKitWrapper()
    let mockNotificationCenter = MockNotificationCenter()
    var userDefaults: UserDefaults! = nil
    let mockOfferingsFactory = MockOfferingsFactory()
    var mockDeviceCache: MockDeviceCache!
    var mockIdentityManager: MockIdentityManager!
    var mockSubscriberAttributesManager: MockSubscriberAttributesManager!
    var subscriberAttributeHeight: SubscriberAttribute!
    var subscriberAttributeWeight: SubscriberAttribute!
    var mockAttributes: [String: SubscriberAttribute]!
    let systemInfo: SystemInfo = MockSystemInfo(finishTransactions: true)
    var mockReceiptParser: MockReceiptParser!
    var mockAttributionFetcher: MockAttributionFetcher!
    var mockAttributionPoster: AttributionPoster!
    var mockTransactionsManager: MockTransactionsManager!
    var mockOperationDispatcher: MockOperationDispatcher!
    var mockIntroEligibilityCalculator: MockIntroEligibilityCalculator!

    // swiftlint:disable:next weak_delegate
    var purchasesDelegate = MockPurchasesDelegate()
    var customerInfoManager: CustomerInfoManager!
    let emptyCustomerInfoData: [String: Any] = [
        "request_date": "2019-08-16T10:30:42Z",
        "subscriber": [
            "first_seen": "2019-07-17T00:05:54Z",
            "original_app_user_id": "",
            "subscriptions": [:],
            "other_purchases": [:],
            "original_application_version": NSNull()
        ]]

    var mockOfferingsManager: MockOfferingsManager!
    var mockManageSubsHelper: MockManageSubscriptionsHelper!
    var mockBeginRefundRequestHelper: MockBeginRefundRequestHelper!

    var purchases: Purchases!

    override func setUpWithError() throws {
        try super.setUpWithError()

        userDefaults = UserDefaults(suiteName: "TestDefaults")
        self.mockDeviceCache = MockDeviceCache(systemInfo: self.systemInfo,
                                               userDefaults: self.userDefaults)

        self.subscriberAttributeHeight = SubscriberAttribute(withKey: "height",
                                                             value: "183")
        self.subscriberAttributeWeight = SubscriberAttribute(withKey: "weight",
                                                             value: "160")
        self.mockAttributes = [
            subscriberAttributeHeight.key: subscriberAttributeHeight,
            subscriberAttributeWeight.key: subscriberAttributeWeight
        ]
        self.mockOperationDispatcher = MockOperationDispatcher()
        self.mockReceiptParser = MockReceiptParser()
        self.mockProductsManager = MockProductsManager(systemInfo: systemInfo)
        self.mockIntroEligibilityCalculator = MockIntroEligibilityCalculator(productsManager: mockProductsManager,
                                                                             receiptParser: mockReceiptParser)
        let platformInfo = Purchases.PlatformInfo(flavor: "iOS", version: "3.2.1")
        let systemInfoAttribution = try MockSystemInfo(platformInfo: platformInfo,
                                                       finishTransactions: true)
        self.mockAttributionFetcher = MockAttributionFetcher(attributionFactory: AttributionTypeFactory(),
                                                             systemInfo: systemInfoAttribution)
        self.mockSubscriberAttributesManager = MockSubscriberAttributesManager(
            backend: self.mockBackend,
            deviceCache: self.mockDeviceCache,
            operationDispatcher: self.mockOperationDispatcher,
            attributionFetcher: self.mockAttributionFetcher,
            attributionDataMigrator: AttributionDataMigrator())
        self.mockIdentityManager = MockIdentityManager(mockAppUserID: "app_user")
        self.mockAttributionPoster = AttributionPoster(deviceCache: mockDeviceCache,
                                                       currentUserProvider: mockIdentityManager,
                                                       backend: mockBackend,
                                                       attributionFetcher: mockAttributionFetcher,
                                                       subscriberAttributesManager: mockSubscriberAttributesManager)
        self.customerInfoManager = CustomerInfoManager(operationDispatcher: mockOperationDispatcher,
                                                       deviceCache: mockDeviceCache,
                                                       backend: mockBackend,
                                                       systemInfo: systemInfo)
        mockOfferingsManager = MockOfferingsManager(deviceCache: mockDeviceCache,
                                                    operationDispatcher: mockOperationDispatcher,
                                                    systemInfo: systemInfo,
                                                    backend: mockBackend,
                                                    offeringsFactory: MockOfferingsFactory(),
                                                    productsManager: mockProductsManager)
        self.mockReceiptFetcher = MockReceiptFetcher(
            requestFetcher: mockRequestFetcher,
            systemInfo: systemInfoAttribution
        )
        self.mockManageSubsHelper = MockManageSubscriptionsHelper(systemInfo: systemInfo,
                                                                  customerInfoManager: customerInfoManager,
                                                                  currentUserProvider: mockIdentityManager)
        self.mockBeginRefundRequestHelper = MockBeginRefundRequestHelper(systemInfo: systemInfo,
                                                                         customerInfoManager: customerInfoManager,
                                                                         currentUserProvider: mockIdentityManager)
        self.mockTransactionsManager = MockTransactionsManager(storeKit2Setting: systemInfo.storeKit2Setting,
                                                               receiptParser: mockReceiptParser)
    }

    override func tearDown() {
        purchases?.delegate = nil
        purchases = nil
        UserDefaults().removePersistentDomain(forName: "TestDefaults")
    }

    func setupPurchases(automaticCollection: Bool = false) {
        Purchases.automaticAppleSearchAdsAttributionCollection = automaticCollection
        self.mockIdentityManager.mockIsAnonymous = false
        let purchasesOrchestrator = PurchasesOrchestrator(productsManager: mockProductsManager,
                                                          storeKitWrapper: mockStoreKitWrapper,
                                                          systemInfo: systemInfo,
                                                          subscriberAttributesManager: mockSubscriberAttributesManager,
                                                          operationDispatcher: mockOperationDispatcher,
                                                          receiptFetcher: mockReceiptFetcher,
                                                          customerInfoManager: customerInfoManager,
                                                          backend: mockBackend,
                                                          currentUserProvider: mockIdentityManager,
                                                          transactionsManager: mockTransactionsManager,
                                                          deviceCache: mockDeviceCache,
                                                          manageSubscriptionsHelper: mockManageSubsHelper,
                                                          beginRefundRequestHelper: mockBeginRefundRequestHelper)
        let trialOrIntroductoryPriceEligibilityChecker = TrialOrIntroPriceEligibilityChecker(
            systemInfo: systemInfo,
            receiptFetcher: mockReceiptFetcher,
            introEligibilityCalculator: mockIntroEligibilityCalculator,
            backend: mockBackend,
            currentUserProvider: mockIdentityManager,
            operationDispatcher: mockOperationDispatcher,
            productsManager: mockProductsManager
        )
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
                              customerInfoManager: customerInfoManager,
                              productsManager: mockProductsManager,
                              offeringsManager: mockOfferingsManager,
                              purchasesOrchestrator: purchasesOrchestrator,
                              trialOrIntroPriceEligibilityChecker: trialOrIntroductoryPriceEligibilityChecker)
        purchasesOrchestrator.delegate = purchases
        purchases!.delegate = purchasesDelegate
        Purchases.setDefaultInstance(purchases!)
    }

    // MARK: Notifications

    func testSubscribesToForegroundNotifications() {
        setupPurchases()

        expect(self.mockNotificationCenter.observers.count) > 0

        var isObservingDidBecomeActive = false

        for (_, _, name, _) in self.mockNotificationCenter.observers
        where name == SystemInfo.applicationDidBecomeActiveNotification {
            isObservingDidBecomeActive = true
            break
        }
        expect(isObservingDidBecomeActive) == true

        self.mockNotificationCenter.fireNotifications()
        expect(self.mockSubscriberAttributesManager.invokedSyncAttributesForAllUsersCount) == 2
    }

    func testSubscribesToBackgroundNotifications() {
        setupPurchases()

        expect(self.mockNotificationCenter.observers.count) > 0

        var isObservingDidBecomeActive = false

        for (_, _, name, _) in self.mockNotificationCenter.observers
        where name == SystemInfo.applicationWillResignActiveNotification {
            isObservingDidBecomeActive = true
            break
        }
        expect(isObservingDidBecomeActive) == true

        self.mockNotificationCenter.fireNotifications()
        expect(self.mockSubscriberAttributesManager.invokedSyncAttributesForAllUsersCount) == 2
    }

    func testSubscriberAttributesSyncIsPerformedAfterCustomerInfoSync() {
        mockBackend.stubbedGetCustomerInfoResult = .success(
            CustomerInfo(testData: [
                "request_date": "2019-08-16T10:30:42Z",
                "subscriber": [
                    "first_seen": "2019-07-17T00:05:54Z",
                    "original_app_user_id": "app_user_id",
                    "subscriptions": [:],
                    "other_purchases": [:],
                    "original_application_version": "1.0",
                    "original_purchase_date": "2018-10-26T23:17:53Z"
                ]
            ])!
        )

        setupPurchases()

        expect(self.mockBackend.invokedGetSubscriberDataCount) == 1
        expect(self.mockDeviceCache.cacheCustomerInfoCount) == 1
        expect(self.mockDeviceCache.cachedCustomerInfo.count) == 1
        expect(self.mockSubscriberAttributesManager.invokedSyncAttributesForAllUsersCount) == 0

        self.mockNotificationCenter.fireNotifications()

        expect(self.mockSubscriberAttributesManager.invokedSyncAttributesForAllUsersCount) == 2
        expect(self.mockDeviceCache.cacheCustomerInfoCount) == 1
        expect(self.mockDeviceCache.cachedCustomerInfo.count) == 1
    }

    // MARK: Set attributes

    func testSetAttributesMakesRightCalls() {
        setupPurchases()

        Purchases.shared.setAttributes(["genre": "rock n' roll"])
        expect(self.mockSubscriberAttributesManager.invokedSetAttributesCount) == 1

        let invokedSetAttributesParameters = self.mockSubscriberAttributesManager.invokedSetAttributesParameters
        expect(invokedSetAttributesParameters?.attributes) == ["genre": "rock n' roll"]
        expect(invokedSetAttributesParameters?.appUserID) == mockIdentityManager.currentAppUserID
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

    func testSetAndClearEmail() {
        setupPurchases()
        purchases.setEmail("taquitos@revenuecat.com")
        purchases.setEmail(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetEmailParametersList[0])
            .to(equal(("taquitos@revenuecat.com", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetEmailParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearPhone() {
        setupPurchases()
        purchases.setPhoneNumber("8000000000")
        purchases.setPhoneNumber(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetPhoneNumberParametersList[0])
            .to(equal(("8000000000", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetPhoneNumberParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearDisplayName() {
        setupPurchases()
        purchases.setDisplayName("taquitos")
        purchases.setDisplayName(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetDisplayNameParametersList[0])
            .to(equal(("taquitos", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetDisplayNameParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearPushToken() {
        setupPurchases()
        purchases.setPushToken("atoken".data(using: .utf8))
        purchases.setPushToken(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetPushTokenParametersList[0])
            .to(equal(("atoken".data(using: .utf8), purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetPushTokenParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearPushTokenString() {
        setupPurchases()
        purchases.setPushTokenString("atoken")
        purchases.setPushTokenString(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetPushTokenStringParametersList[0])
            .to(equal(("atoken", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetPushTokenStringParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearAdjustID() {
        setupPurchases()
        purchases.setAdjustID("adjustIt")
        purchases.setAdjustID(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetAdjustIDParametersList[0])
            .to(equal(("adjustIt", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetAdjustIDParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearAppsflyerID() {
        setupPurchases()
        purchases.setAppsflyerID("appsFly")
        purchases.setAppsflyerID(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetAppsflyerIDParametersList[0])
            .to(equal(("appsFly", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetAppsflyerIDParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearFBAnonymousID() {
        setupPurchases()
        purchases.setFBAnonymousID("fb")
        purchases.setFBAnonymousID(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetFBAnonymousIDParametersList[0])
            .to(equal(("fb", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetFBAnonymousIDParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearMparticleID() {
        setupPurchases()
        purchases.setMparticleID("Mpart")
        purchases.setMparticleID(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetMparticleIDParametersList[0])
            .to(equal(("Mpart", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetMparticleIDParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearOnesignalID() {
        setupPurchases()
        purchases.setOnesignalID("oneSig")
        purchases.setOnesignalID(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetOnesignalIDParametersList[0])
            .to(equal(("oneSig", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetOnesignalIDParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearAirshipChannelID() {
        setupPurchases()
        purchases.setAirshipChannelID("airship")
        purchases.setAirshipChannelID(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetAirshipChannelIDParametersList[0])
            .to(equal(("airship", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetAirshipChannelIDParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearCleverTapID() {
        setupPurchases()
        purchases.setCleverTapID("clever")
        purchases.setCleverTapID(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetCleverTapIDParametersList[0])
            .to(equal(("clever", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetCleverTapIDParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearMixpanelDistinctID() {
        setupPurchases()
        purchases.setMixpanelDistinctID("mixp")
        purchases.setMixpanelDistinctID(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetMixpanelDistinctIDParametersList[0])
            .to(equal(("mixp", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetMixpanelDistinctIDParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearFirebaseAppInstanceID() {
        setupPurchases()
        purchases.setFirebaseAppInstanceID("fireb")
        purchases.setFirebaseAppInstanceID(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetFirebaseAppInstanceIDParametersList[0]) ==
        ("fireb", purchases.appUserID)
        expect(self.mockSubscriberAttributesManager.invokedSetFirebaseAppInstanceIDParametersList[1]) ==
        (nil, purchases.appUserID)
    }

    func testSetAndClearMediaSource() {
        setupPurchases()
        purchases.setMediaSource("media")
        purchases.setMediaSource(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetMediaSourceParametersList[0])
            .to(equal(("media", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetMediaSourceParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearCampaign() {
        setupPurchases()
        purchases.setCampaign("testCampaign")
        purchases.setCampaign(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetCampaignParametersList[0])
            .to(equal(("testCampaign", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetCampaignParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearAdGroup() {
        setupPurchases()
        purchases.setAdGroup("anAdGroup")
        purchases.setAdGroup(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetAdGroupParametersList[0])
            .to(equal(("anAdGroup", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetAdGroupParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearAd() {
        setupPurchases()
        purchases.setAd("anAd")
        purchases.setAd(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetAdParametersList[0])
            .to(equal(("anAd", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetAdParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearKeyword() {
        setupPurchases()
        purchases.setKeyword("Akeyword")
        purchases.setKeyword(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetKeywordParametersList[0])
            .to(equal(("Akeyword", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetKeywordParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearCreative() {
        setupPurchases()
        purchases.setCreative("ImAnArtist")
        purchases.setCreative(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetCreativeParametersList[0])
            .to(equal(("ImAnArtist", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetCreativeParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetDisplayNameMakesRightCalls() {
        setupPurchases()

        Purchases.shared.setDisplayName("Stevie Ray Vaughan")
        expect(self.mockSubscriberAttributesManager.invokedSetDisplayNameCount) == 1

        let invokedSetDisplayNameParameters = self.mockSubscriberAttributesManager.invokedSetDisplayNameParameters
        expect(invokedSetDisplayNameParameters?.displayName) == "Stevie Ray Vaughan"
        expect(invokedSetDisplayNameParameters?.appUserID) == mockIdentityManager
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

        Purchases.shared.setPushTokenString(tokenString)
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

    func testSetAirshipChannelIDMakesRightCalls() {
        setupPurchases()

        Purchases.shared.setAirshipChannelID("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetAirshipChannelIDCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetAirshipChannelIDParameters?.airshipChannelID) == "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetAirshipChannelIDParameters?.appUserID) ==
        mockIdentityManager.currentAppUserID
    }

    func testSetMixpanelDistinctIDMakesRightCalls() {
        setupPurchases()

        Purchases.shared.setMixpanelDistinctID("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetMixpanelDistinctIDCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetMixpanelDistinctIDParameters?.mixpanelDistinctID) ==
        "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetMixpanelDistinctIDParameters?.appUserID) ==
        mockIdentityManager.currentAppUserID
    }

    func testSetFirebaseAppInstanceIDMakesRightCalls() {
        setupPurchases()

        Purchases.shared.setFirebaseAppInstanceID("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetFirebaseAppInstanceIDCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetFirebaseAppInstanceIDParameters?.firebaseAppInstanceID) ==
        "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetFirebaseAppInstanceIDParameters?.appUserID) ==
        mockIdentityManager.currentAppUserID
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
        expect(self.mockSubscriberAttributesManager.invokedSetCreativeParameters?.appUserID) ==
        mockIdentityManager.currentAppUserID
    }

    func testCollectDeviceIdentifiersMakesRightCalls() {
        setupPurchases()

        Purchases.shared.collectDeviceIdentifiers()
        expect(self.mockSubscriberAttributesManager.invokedCollectDeviceIdentifiersCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedCollectDeviceIdentifiersParameters?.appUserID) ==
        mockIdentityManager.currentAppUserID
    }

    // MARK: Post receipt with attributes

    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    func testPostReceiptMarksSubscriberAttributesSyncedIfBackendSuccessful() {
        setupPurchases()
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases?.purchase(product: product) { (_, _, _, _) in }
        mockSubscriberAttributesManager.stubbedUnsyncedAttributesByKeyResult = mockAttributes

        let transaction = MockTransaction()
        transaction.mockPayment = self.mockStoreKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.mockStoreKitWrapper.delegate?.storeKitWrapper(self.mockStoreKitWrapper, updatedTransaction: transaction)

        self.mockBackend.stubbedPostReceiptResult = .success(CustomerInfo(testData: emptyCustomerInfoData)!)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.mockStoreKitWrapper.delegate?.storeKitWrapper(self.mockStoreKitWrapper, updatedTransaction: transaction)

        expect(self.mockBackend.invokedPostReceiptData).to(beTrue())
        expect(self.mockStoreKitWrapper.finishCalled).toEventually(beTrue())
        expect(self.mockSubscriberAttributesManager.invokedMarkAttributes) == true
        expect(self.mockSubscriberAttributesManager.invokedMarkAttributesParameters!.syncedAttributes) == mockAttributes
        expect(self.mockSubscriberAttributesManager.invokedMarkAttributesParameters!.appUserID) ==
        mockIdentityManager.currentAppUserID
    }

    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    func testPostReceiptMarksSubscriberAttributesSyncedIfBackendSuccessfullySynced() {
        setupPurchases()
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases?.purchase(product: product) { (_, _, _, _) in }
        mockSubscriberAttributesManager.stubbedUnsyncedAttributesByKeyResult = mockAttributes

        let transaction = MockTransaction()
        transaction.mockPayment = self.mockStoreKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.mockStoreKitWrapper.delegate?.storeKitWrapper(self.mockStoreKitWrapper, updatedTransaction: transaction)

        self.mockBackend.stubbedPostReceiptResult = .failure(
            .networkError(.errorResponse(
                .init(code: .invalidAPIKey, message: "Invalid credentials"),
                400)
            )
        )

        transaction.mockState = SKPaymentTransactionState.purchased
        self.mockStoreKitWrapper.delegate?.storeKitWrapper(self.mockStoreKitWrapper, updatedTransaction: transaction)

        expect(self.mockBackend.invokedPostReceiptData) == true
        expect(self.mockSubscriberAttributesManager.invokedMarkAttributes) == true
        expect(self.mockSubscriberAttributesManager.invokedMarkAttributesParameters?.syncedAttributes) == mockAttributes
        expect(self.mockSubscriberAttributesManager.invokedMarkAttributesParameters?.appUserID) ==
        mockIdentityManager.currentAppUserID
    }

    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    func testPostReceiptDoesntMarkSubscriberAttributesSyncedIfBackendNotSuccessfullySynced() {
        setupPurchases()
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases?.purchase(product: product) { (_, _, _, _) in }
        mockSubscriberAttributesManager.stubbedUnsyncedAttributesByKeyResult = mockAttributes

        let transaction = MockTransaction()
        transaction.mockPayment = self.mockStoreKitWrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.mockStoreKitWrapper.delegate?.storeKitWrapper(self.mockStoreKitWrapper, updatedTransaction: transaction)

        self.mockBackend.stubbedPostReceiptResult = .failure(
            .networkError(.errorResponse(
                .init(code: .internalServerError, message: "Error", attributeErrors: [:]),
                .internalServerError)
            )
        )

        transaction.mockState = SKPaymentTransactionState.purchased
        self.mockStoreKitWrapper.delegate?.storeKitWrapper(self.mockStoreKitWrapper, updatedTransaction: transaction)

        expect(self.mockBackend.invokedPostReceiptData).to(beTrue())
        expect(self.mockSubscriberAttributesManager.invokedMarkAttributes) == false
    }

}
