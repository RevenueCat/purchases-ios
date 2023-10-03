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
    let mockStoreKit1Wrapper = MockStoreKit1Wrapper()
    let mockNotificationCenter = MockNotificationCenter()
    var userDefaults: UserDefaults! = nil
    let mockOfferingsFactory = MockOfferingsFactory()
    var mockDeviceCache: MockDeviceCache!
    var mockIdentityManager: MockIdentityManager!
    var mockSubscriberAttributesManager: MockSubscriberAttributesManager!
    var attribution: Attribution!
    var subscriberAttributeHeight: SubscriberAttribute!
    var subscriberAttributeWeight: SubscriberAttribute!
    var mockAttributes: [String: SubscriberAttribute]!
    var systemInfo: MockSystemInfo!
    var clock: TestClock!
    var mockReceiptParser: MockReceiptParser!
    var mockAttributionFetcher: MockAttributionFetcher!
    var mockAttributionPoster: AttributionPoster!
    var mockTransactionsManager: MockTransactionsManager!
    var mockOperationDispatcher: MockOperationDispatcher!
    var mockIntroEligibilityCalculator: MockIntroEligibilityCalculator!
    var transactionPoster: TransactionPoster!

    // swiftlint:disable:next weak_delegate
    var purchasesDelegate = MockPurchasesDelegate()
    var customerInfoManager: CustomerInfoManager!
    let emptyCustomerInfoData: [String: Any] = [
        "request_date": "2019-08-16T10:30:42Z",
        "subscriber": [
            "first_seen": "2019-07-17T00:05:54Z",
            "original_app_user_id": "",
            "subscriptions": [:] as [String: Any],
            "other_purchases": [:] as [String: Any],
            "original_application_version": NSNull()
        ] as [String: Any]
    ]

    var mockOfferingsManager: MockOfferingsManager!
    var mockOfflineEntitlementsManager: MockOfflineEntitlementsManager!
    var mockPurchasedProductsFetcher: MockPurchasedProductsFetcher!
    var mockManageSubsHelper: MockManageSubscriptionsHelper!
    var mockBeginRefundRequestHelper: MockBeginRefundRequestHelper!
    var mockStoreMessagesHelper: MockStoreMessagesHelper!

    var purchases: Purchases!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.userDefaults = UserDefaults(suiteName: "TestDefaults")
        self.clock = TestClock()
        self.systemInfo = MockSystemInfo(finishTransactions: true, clock: self.clock)

        self.mockDeviceCache = MockDeviceCache(sandboxEnvironmentDetector: self.systemInfo,
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
        self.mockProductsManager = MockProductsManager(systemInfo: systemInfo,
                                                       requestTimeout: Configuration.storeKitRequestTimeoutDefault)
        self.mockIntroEligibilityCalculator = MockIntroEligibilityCalculator(productsManager: mockProductsManager,
                                                                             receiptParser: mockReceiptParser)
        let platformInfo = Purchases.PlatformInfo(flavor: "iOS", version: "3.2.1")
        let systemInfoAttribution = MockSystemInfo(platformInfo: platformInfo,
                                                   finishTransactions: true)
        self.mockAttributionFetcher = MockAttributionFetcher(attributionFactory: AttributionTypeFactory(),
                                                             systemInfo: systemInfoAttribution)
        self.mockSubscriberAttributesManager = MockSubscriberAttributesManager(
            backend: self.mockBackend,
            deviceCache: self.mockDeviceCache,
            operationDispatcher: self.mockOperationDispatcher,
            attributionFetcher: self.mockAttributionFetcher,
            attributionDataMigrator: AttributionDataMigrator()
        )
        self.mockIdentityManager = MockIdentityManager(mockAppUserID: "app_user", mockDeviceCache: self.mockDeviceCache)
        self.mockAttributionPoster = AttributionPoster(deviceCache: self.mockDeviceCache,
                                                       currentUserProvider: mockIdentityManager,
                                                       backend: mockBackend,
                                                       attributionFetcher: mockAttributionFetcher,
                                                       subscriberAttributesManager: mockSubscriberAttributesManager)
        self.attribution = Attribution(subscriberAttributesManager: self.mockSubscriberAttributesManager,
                                       currentUserProvider: self.mockIdentityManager,
                                       attributionPoster: self.mockAttributionPoster,
                                       systemInfo: self.systemInfo)
        self.mockOfflineEntitlementsManager = MockOfflineEntitlementsManager()
        self.mockPurchasedProductsFetcher = MockPurchasedProductsFetcher()
        self.mockReceiptFetcher = MockReceiptFetcher(
            requestFetcher: self.mockRequestFetcher,
            systemInfo: systemInfoAttribution
        )

        self.transactionPoster = TransactionPoster(
            productsManager: self.mockProductsManager,
            receiptFetcher: self.mockReceiptFetcher,
            backend: self.mockBackend,
            paymentQueueWrapper: self.paymentQueueWrapper,
            systemInfo: self.systemInfo,
            operationDispatcher: self.mockOperationDispatcher
        )

        self.customerInfoManager = CustomerInfoManager(offlineEntitlementsManager: self.mockOfflineEntitlementsManager,
                                                       operationDispatcher: self.mockOperationDispatcher,
                                                       deviceCache: self.mockDeviceCache,
                                                       backend: self.mockBackend,
                                                       transactionFetcher: MockStoreKit2TransactionFetcher(),
                                                       transactionPoster: self.transactionPoster,
                                                       systemInfo: self.systemInfo)
        self.mockOfferingsManager = MockOfferingsManager(deviceCache: mockDeviceCache,
                                                         operationDispatcher: mockOperationDispatcher,
                                                         systemInfo: systemInfo,
                                                         backend: mockBackend,
                                                         offeringsFactory: MockOfferingsFactory(),
                                                         productsManager: mockProductsManager)
        self.mockManageSubsHelper = MockManageSubscriptionsHelper(systemInfo: systemInfo,
                                                                  customerInfoManager: customerInfoManager,
                                                                  currentUserProvider: mockIdentityManager)
        self.mockBeginRefundRequestHelper = MockBeginRefundRequestHelper(systemInfo: systemInfo,
                                                                         customerInfoManager: customerInfoManager,
                                                                         currentUserProvider: mockIdentityManager)
        self.mockTransactionsManager = MockTransactionsManager(receiptParser: mockReceiptParser)
        self.mockStoreMessagesHelper = .init()
    }

    override func tearDown() {
        Purchases.clearSingleton()

        self.purchases?.delegate = nil
        self.purchases = nil
        UserDefaults().removePersistentDomain(forName: "TestDefaults")

        super.tearDown()
    }

    func setupPurchases(automaticCollection: Bool = false) {
        Purchases.deprecated.automaticAppleSearchAdsAttributionCollection = automaticCollection

        self.mockIdentityManager.mockIsAnonymous = false

        let purchasesOrchestrator = PurchasesOrchestrator(productsManager: self.mockProductsManager,
                                                          paymentQueueWrapper: self.paymentQueueWrapper,
                                                          systemInfo: self.systemInfo,
                                                          subscriberAttributes: self.attribution,
                                                          operationDispatcher: self.mockOperationDispatcher,
                                                          receiptFetcher: self.mockReceiptFetcher,
                                                          receiptParser: self.mockReceiptParser,
                                                          customerInfoManager: self.customerInfoManager,
                                                          backend: self.mockBackend,
                                                          transactionPoster: self.transactionPoster,
                                                          currentUserProvider: self.mockIdentityManager,
                                                          transactionsManager: self.mockTransactionsManager,
                                                          deviceCache: self.mockDeviceCache,
                                                          offeringsManager: self.mockOfferingsManager,
                                                          manageSubscriptionsHelper: self.mockManageSubsHelper,
                                                          beginRefundRequestHelper: self.mockBeginRefundRequestHelper,
                                                          storeMessagesHelper: self.mockStoreMessagesHelper)
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
                              paymentQueueWrapper: .left(self.mockStoreKit1Wrapper),
                              userDefaults: .computeDefault(),
                              notificationCenter: mockNotificationCenter,
                              systemInfo: systemInfo,
                              offeringsFactory: mockOfferingsFactory,
                              deviceCache: mockDeviceCache,
                              paywallCache: MockPaywallCacheWarming(),
                              identityManager: mockIdentityManager,
                              subscriberAttributes: attribution,
                              operationDispatcher: mockOperationDispatcher,
                              customerInfoManager: customerInfoManager,
                              paywallEventsManager: nil,
                              productsManager: mockProductsManager,
                              offeringsManager: mockOfferingsManager,
                              offlineEntitlementsManager: mockOfflineEntitlementsManager,
                              purchasesOrchestrator: purchasesOrchestrator,
                              purchasedProductsFetcher: mockPurchasedProductsFetcher,
                              trialOrIntroPriceEligibilityChecker: .create(
                                with: trialOrIntroductoryPriceEligibilityChecker
                              ),
                              storeMessagesHelper: self.mockStoreMessagesHelper)
        purchasesOrchestrator.delegate = purchases
        purchases!.delegate = purchasesDelegate
        Purchases.setDefaultInstance(purchases!)
    }

    private var paymentQueueWrapper: EitherPaymentQueueWrapper {
        return .left(self.mockStoreKit1Wrapper)
    }

    // MARK: Notifications

    func testSubscribesToForegroundNotifications() {
        setupPurchases()

        expect(self.mockNotificationCenter.observers).toNot(beEmpty())

        expect(self.mockNotificationCenter.observers).to(containElementSatisfying {
            $0.notificationName == SystemInfo.applicationWillEnterForegroundNotification
        })

        self.mockNotificationCenter.fireNotifications()
        expect(self.mockSubscriberAttributesManager.invokedSyncAttributesForAllUsersCount) == 2
    }

    func testSubscribesToBackgroundNotifications() {
        setupPurchases()

        expect(self.mockNotificationCenter.observers).toNot(beEmpty())

        expect(self.mockNotificationCenter.observers).to(containElementSatisfying {
            $0.notificationName == SystemInfo.applicationDidEnterBackgroundNotification
        })

        self.mockNotificationCenter.fireNotifications()
        expect(self.mockSubscriberAttributesManager.invokedSyncAttributesForAllUsersCount) == 2
    }

    func testSubscriberAttributesSyncIsPerformedAfterCustomerInfoSync() throws {
        self.mockBackend.stubbedGetCustomerInfoResult = .success(.emptyInfo)

        self.setupPurchases()

        expect(self.mockBackend.invokedGetSubscriberDataCount).toEventually(equal(1))
        expect(self.mockDeviceCache.cacheCustomerInfoCount).toEventually(equal(1))
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

        Purchases.shared.attribution.setAttributes(["genre": "rock n' roll"])
        expect(self.mockSubscriberAttributesManager.invokedSetAttributesCount) == 1

        let invokedSetAttributesParameters = self.mockSubscriberAttributesManager.invokedSetAttributesParameters
        expect(invokedSetAttributesParameters?.attributes) == ["genre": "rock n' roll"]
        expect(invokedSetAttributesParameters?.appUserID) == mockIdentityManager.currentAppUserID
    }

    func testSetEmailMakesRightCalls() {
        setupPurchases()

        Purchases.shared.attribution.setEmail("ac.dc@rock.com")
        expect(self.mockSubscriberAttributesManager.invokedSetEmailCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetEmailParameters?.email) == "ac.dc@rock.com"
        expect(self.mockSubscriberAttributesManager.invokedSetEmailParameters?.appUserID) == mockIdentityManager
            .currentAppUserID
    }

    func testSetPhoneNumberMakesRightCalls() {
        setupPurchases()

        Purchases.shared.attribution.setPhoneNumber("8561365841")
        expect(self.mockSubscriberAttributesManager.invokedSetPhoneNumberCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetPhoneNumberParameters?.phoneNumber) == "8561365841"
        expect(self.mockSubscriberAttributesManager.invokedSetPhoneNumberParameters?.appUserID) == mockIdentityManager
            .currentAppUserID
    }

    func testSetAndClearEmail() {
        setupPurchases()
        purchases.attribution.setEmail("taquitos@revenuecat.com")
        purchases.attribution.setEmail(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetEmailParametersList[0])
            .to(equal(("taquitos@revenuecat.com", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetEmailParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearPhone() {
        setupPurchases()
        purchases.attribution.setPhoneNumber("8000000000")
        purchases.attribution.setPhoneNumber(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetPhoneNumberParametersList[0])
            .to(equal(("8000000000", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetPhoneNumberParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearDisplayName() {
        setupPurchases()
        purchases.attribution.setDisplayName("taquitos")
        purchases.attribution.setDisplayName(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetDisplayNameParametersList[0])
            .to(equal(("taquitos", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetDisplayNameParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearPushToken() {
        setupPurchases()
        purchases.attribution.setPushToken("atoken".asData)
        purchases.attribution.setPushToken(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetPushTokenParametersList[0])
            .to(equal(("atoken".asData, purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetPushTokenParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearPushTokenString() {
        setupPurchases()
        purchases.attribution.setPushTokenString("atoken")
        purchases.attribution.setPushTokenString(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetPushTokenStringParametersList[0])
            .to(equal(("atoken", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetPushTokenStringParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearAdjustID() {
        setupPurchases()
        purchases.attribution.setAdjustID("adjustIt")
        purchases.attribution.setAdjustID(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetAdjustIDParametersList[0])
            .to(equal(("adjustIt", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetAdjustIDParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearAppsflyerID() {
        setupPurchases()
        purchases.attribution.setAppsflyerID("appsFly")
        purchases.attribution.setAppsflyerID(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetAppsflyerIDParametersList[0])
            .to(equal(("appsFly", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetAppsflyerIDParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearFBAnonymousID() {
        setupPurchases()
        purchases.attribution.setFBAnonymousID("fb")
        purchases.attribution.setFBAnonymousID(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetFBAnonymousIDParametersList[0])
            .to(equal(("fb", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetFBAnonymousIDParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearMparticleID() {
        setupPurchases()
        purchases.attribution.setMparticleID("Mpart")
        purchases.attribution.setMparticleID(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetMparticleIDParametersList[0])
            .to(equal(("Mpart", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetMparticleIDParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearOnesignalID() {
        setupPurchases()
        purchases.attribution.setOnesignalID("oneSig")
        purchases.attribution.setOnesignalID(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetOnesignalIDParametersList[0])
            .to(equal(("oneSig", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetOnesignalIDParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearAirshipChannelID() {
        setupPurchases()
        purchases.attribution.setAirshipChannelID("airship")
        purchases.attribution.setAirshipChannelID(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetAirshipChannelIDParametersList[0])
            .to(equal(("airship", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetAirshipChannelIDParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearCleverTapID() {
        setupPurchases()
        purchases.attribution.setCleverTapID("clever")
        purchases.attribution.setCleverTapID(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetCleverTapIDParametersList[0])
            .to(equal(("clever", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetCleverTapIDParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearMixpanelDistinctID() {
        setupPurchases()
        purchases.attribution.setMixpanelDistinctID("mixp")
        purchases.attribution.setMixpanelDistinctID(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetMixpanelDistinctIDParametersList[0])
            .to(equal(("mixp", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetMixpanelDistinctIDParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearFirebaseAppInstanceID() {
        setupPurchases()
        purchases.attribution.setFirebaseAppInstanceID("fireb")
        purchases.attribution.setFirebaseAppInstanceID(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetFirebaseAppInstanceIDParametersList[0]) ==
        ("fireb", purchases.appUserID)
        expect(self.mockSubscriberAttributesManager.invokedSetFirebaseAppInstanceIDParametersList[1]) ==
        (nil, purchases.appUserID)
    }

    func testSetAndClearMediaSource() {
        setupPurchases()
        purchases.attribution.setMediaSource("media")
        purchases.attribution.setMediaSource(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetMediaSourceParametersList[0])
            .to(equal(("media", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetMediaSourceParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearCampaign() {
        setupPurchases()
        purchases.attribution.setCampaign("testCampaign")
        purchases.attribution.setCampaign(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetCampaignParametersList[0])
            .to(equal(("testCampaign", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetCampaignParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearAdGroup() {
        setupPurchases()
        purchases.attribution.setAdGroup("anAdGroup")
        purchases.attribution.setAdGroup(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetAdGroupParametersList[0])
            .to(equal(("anAdGroup", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetAdGroupParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearAd() {
        setupPurchases()
        purchases.attribution.setAd("anAd")
        purchases.attribution.setAd(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetAdParametersList[0])
            .to(equal(("anAd", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetAdParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearKeyword() {
        setupPurchases()
        purchases.attribution.setKeyword("Akeyword")
        purchases.attribution.setKeyword(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetKeywordParametersList[0])
            .to(equal(("Akeyword", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetKeywordParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetAndClearCreative() {
        setupPurchases()
        purchases.attribution.setCreative("ImAnArtist")
        purchases.attribution.setCreative(nil)
        expect(self.mockSubscriberAttributesManager.invokedSetCreativeParametersList[0])
            .to(equal(("ImAnArtist", purchases.appUserID)))
        expect(self.mockSubscriberAttributesManager.invokedSetCreativeParametersList[1])
            .to(equal((nil, purchases.appUserID)))
    }

    func testSetDisplayNameMakesRightCalls() {
        setupPurchases()

        Purchases.shared.attribution.setDisplayName("Stevie Ray Vaughan")
        expect(self.mockSubscriberAttributesManager.invokedSetDisplayNameCount) == 1

        let invokedSetDisplayNameParameters = self.mockSubscriberAttributesManager.invokedSetDisplayNameParameters
        expect(invokedSetDisplayNameParameters?.displayName) == "Stevie Ray Vaughan"
        expect(invokedSetDisplayNameParameters?.appUserID) == mockIdentityManager
            .currentAppUserID
    }

    func testSetPushTokenMakesRightCalls() {
        setupPurchases()
        let tokenData = "ligai32g32ig".asData
        let tokenString = tokenData.asString

        Purchases.shared.attribution.setPushToken(tokenData)
        expect(self.mockSubscriberAttributesManager.invokedSetPushTokenCount) == 1

        let receivedPushToken = self.mockSubscriberAttributesManager.invokedSetPushTokenParameters!.pushToken!

        expect(receivedPushToken.asString) == tokenString
        expect(self.mockSubscriberAttributesManager.invokedSetPushTokenParameters?.appUserID) == mockIdentityManager
            .currentAppUserID
    }

    func testSetPushTokenStringMakesRightCalls() {
        setupPurchases()
        let tokenString = "ligai32g32ig"

        Purchases.shared.attribution.setPushTokenString(tokenString)
        expect(self.mockSubscriberAttributesManager.invokedSetPushTokenStringCount) == 1

        let receivedPushToken = self.mockSubscriberAttributesManager.invokedSetPushTokenStringParameters!.pushToken!

        expect(receivedPushToken) == tokenString
        expect(self.mockSubscriberAttributesManager.invokedSetPushTokenStringParameters?.appUserID) ==
        mockIdentityManager.currentAppUserID
    }

    func testSetAdjustIDMakesRightCalls() {
        setupPurchases()

        Purchases.shared.attribution.setAdjustID("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetAdjustIDCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetAdjustIDParameters?.adjustID) == "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetAdjustIDParameters?.appUserID) == mockIdentityManager
            .currentAppUserID
    }

    func testSetAppsflyerIDMakesRightCalls() {
        setupPurchases()

        Purchases.shared.attribution.setAppsflyerID("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetAppsflyerIDCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetAppsflyerIDParameters?.appsflyerID) == "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetAppsflyerIDParameters?.appUserID) == mockIdentityManager
            .currentAppUserID
    }

    func testSetFBAnonymousIDMakesRightCalls() {
        setupPurchases()

        Purchases.shared.attribution.setFBAnonymousID("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetFBAnonymousIDCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetFBAnonymousIDParameters?.fbAnonymousID) == "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetFBAnonymousIDParameters?.appUserID) == mockIdentityManager
            .currentAppUserID
    }

    func testSetMparticleIDMakesRightCalls() {
        setupPurchases()

        Purchases.shared.attribution.setMparticleID("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetMparticleIDCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetMparticleIDParameters?.mparticleID) == "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetMparticleIDParameters?.appUserID) == mockIdentityManager
            .currentAppUserID
    }

    func testSetOnesignalIDMakesRightCalls() {
        setupPurchases()

        Purchases.shared.attribution.setOnesignalID("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetOnesignalIDCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetOnesignalIDParameters?.onesignalID) == "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetOnesignalIDParameters?.appUserID) == mockIdentityManager
            .currentAppUserID
    }

    func testSetAirshipChannelIDMakesRightCalls() {
        setupPurchases()

        Purchases.shared.attribution.setAirshipChannelID("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetAirshipChannelIDCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetAirshipChannelIDParameters?.airshipChannelID) == "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetAirshipChannelIDParameters?.appUserID) ==
        mockIdentityManager.currentAppUserID
    }

    func testSetMixpanelDistinctIDMakesRightCalls() {
        setupPurchases()

        Purchases.shared.attribution.setMixpanelDistinctID("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetMixpanelDistinctIDCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetMixpanelDistinctIDParameters?.mixpanelDistinctID) ==
        "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetMixpanelDistinctIDParameters?.appUserID) ==
        mockIdentityManager.currentAppUserID
    }

    func testSetFirebaseAppInstanceIDMakesRightCalls() {
        setupPurchases()

        Purchases.shared.attribution.setFirebaseAppInstanceID("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetFirebaseAppInstanceIDCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetFirebaseAppInstanceIDParameters?.firebaseAppInstanceID) ==
        "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetFirebaseAppInstanceIDParameters?.appUserID) ==
        mockIdentityManager.currentAppUserID
    }

    func testSetMediaSourceMakesRightCalls() {
        setupPurchases()

        Purchases.shared.attribution.setMediaSource("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetMediaSourceCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetMediaSourceParameters?.mediaSource) == "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetMediaSourceParameters?.appUserID) == mockIdentityManager
            .currentAppUserID
    }

    func testSetCampaignMakesRightCalls() {
        setupPurchases()

        Purchases.shared.attribution.setCampaign("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetCampaignCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetCampaignParameters?.campaign) == "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetCampaignParameters?.appUserID) == mockIdentityManager
            .currentAppUserID
    }

    func testSetAdGroupMakesRightCalls() {
        setupPurchases()

        Purchases.shared.attribution.setAdGroup("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetAdGroupCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetAdGroupParameters?.adGroup) == "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetAdGroupParameters?.appUserID) == mockIdentityManager
            .currentAppUserID
    }

    func testSetAdMakesRightCalls() {
        setupPurchases()

        Purchases.shared.attribution.setAd("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetAdCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetAdParameters?.ad) == "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetAdParameters?.appUserID) == mockIdentityManager
            .currentAppUserID
    }

    func testSetKeywordMakesRightCalls() {
        setupPurchases()

        Purchases.shared.attribution.setKeyword("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetKeywordCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetKeywordParameters?.keyword) == "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetKeywordParameters?.appUserID) == mockIdentityManager
            .currentAppUserID
    }

    func testSetCreativeMakesRightCalls() {
        setupPurchases()

        Purchases.shared.attribution.setCreative("123abc")
        expect(self.mockSubscriberAttributesManager.invokedSetCreativeCount) == 1
        expect(self.mockSubscriberAttributesManager.invokedSetCreativeParameters?.creative) == "123abc"
        expect(self.mockSubscriberAttributesManager.invokedSetCreativeParameters?.appUserID) ==
        mockIdentityManager.currentAppUserID
    }

    func testCollectDeviceIdentifiersMakesRightCalls() {
        setupPurchases()

        Purchases.shared.attribution.collectDeviceIdentifiers()
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
        transaction.mockPayment = self.mockStoreKit1Wrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.mockStoreKit1Wrapper.delegate?.storeKit1Wrapper(self.mockStoreKit1Wrapper, updatedTransaction: transaction)

        self.mockBackend.stubbedPostReceiptResult = .success(CustomerInfo(testData: emptyCustomerInfoData)!)

        transaction.mockState = SKPaymentTransactionState.purchased
        self.mockStoreKit1Wrapper.delegate?.storeKit1Wrapper(self.mockStoreKit1Wrapper, updatedTransaction: transaction)

        expect(self.mockBackend.invokedPostReceiptData).to(beTrue())
        expect(self.mockStoreKit1Wrapper.finishCalled).toEventually(beTrue())
        expect(self.mockSubscriberAttributesManager.invokedMarkAttributes).toEventually(beTrue())
        expect(self.mockSubscriberAttributesManager.invokedMarkAttributesParameters?.syncedAttributes) == mockAttributes
        expect(self.mockSubscriberAttributesManager.invokedMarkAttributesParameters?.appUserID) ==
        self.mockIdentityManager.currentAppUserID
    }

    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    func testPostReceiptMarksSubscriberAttributesSyncedIfBackendSuccessfullySynced() {
        setupPurchases()
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases?.purchase(product: product) { (_, _, _, _) in }
        mockSubscriberAttributesManager.stubbedUnsyncedAttributesByKeyResult = mockAttributes

        let transaction = MockTransaction()
        transaction.mockPayment = self.mockStoreKit1Wrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.mockStoreKit1Wrapper.delegate?.storeKit1Wrapper(self.mockStoreKit1Wrapper, updatedTransaction: transaction)

        self.mockBackend.stubbedPostReceiptResult = .failure(
            .networkError(.errorResponse(
                .init(code: .invalidAPIKey,
                      originalCode: BackendErrorCode.invalidAPIKey.rawValue,
                      message: "Invalid credentials"),
                400
            ))
        )

        transaction.mockState = SKPaymentTransactionState.purchased
        self.mockStoreKit1Wrapper.delegate?.storeKit1Wrapper(self.mockStoreKit1Wrapper, updatedTransaction: transaction)

        expect(self.mockBackend.invokedPostReceiptData).toEventually(beTrue())
        expect(self.mockSubscriberAttributesManager.invokedMarkAttributes).toEventually(beTrue())
        expect(self.mockSubscriberAttributesManager.invokedMarkAttributesParameters?.syncedAttributes) == mockAttributes
        expect(self.mockSubscriberAttributesManager.invokedMarkAttributesParameters?.appUserID) ==
        mockIdentityManager.currentAppUserID
    }

    @available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    func testPostReceiptMarksAdServicesTokenSyncedIfBackendSuccessfullySynced() throws {
        try AvailabilityChecks.iOS14_3APIAvailableOrSkipTest()
        try AvailabilityChecks.skipIfTVOrWatchOS()

        self.setupPurchases()

        let token = "token"

        self.mockAttributionFetcher.adServicesTokenToReturn = token
        self.attribution.enableAdServicesAttributionTokenCollection()

        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases.purchase(product: product) { (_, _, _, _) in }

        let transaction = MockTransaction()
        transaction.mockPayment = self.mockStoreKit1Wrapper.payment!
        transaction.mockState = .purchasing

        self.mockStoreKit1Wrapper.delegate?.storeKit1Wrapper(self.mockStoreKit1Wrapper, updatedTransaction: transaction)

        self.mockBackend.stubbedPostReceiptResult = .success(try CustomerInfo(data: self.emptyCustomerInfoData))

        transaction.mockState = .purchased
        self.mockStoreKit1Wrapper.delegate?.storeKit1Wrapper(self.mockStoreKit1Wrapper, updatedTransaction: transaction)

        expect(self.mockBackend.invokedPostReceiptData).toEventually(equal(true))
        expect(self.mockDeviceCache.invokedSetLatestNetworkAndAdvertisingIdsSent) == true
        expect(self.mockDeviceCache.invokedSetLatestNetworkAndAdvertisingIdsSentCount) == 1
        expect(self.mockDeviceCache.invokedSetLatestNetworkAndAdvertisingIdsSentParameters) == (
            [.adServices: token], self.mockIdentityManager.currentAppUserID
        )
    }

    @available(iOS 12.2, macOS 10.14.4, watchOS 6.2, macCatalyst 13.0, tvOS 12.2, *)
    func testPostReceiptDoesntMarkSubscriberAttributesSyncedIfBackendNotSuccessfullySynced() {
        setupPurchases()
        let product = StoreProduct(sk1Product: MockSK1Product(mockProductIdentifier: "com.product.id1"))
        self.purchases?.purchase(product: product) { (_, _, _, _) in }
        mockSubscriberAttributesManager.stubbedUnsyncedAttributesByKeyResult = mockAttributes

        let transaction = MockTransaction()
        transaction.mockPayment = self.mockStoreKit1Wrapper.payment!

        transaction.mockState = SKPaymentTransactionState.purchasing
        self.mockStoreKit1Wrapper.delegate?.storeKit1Wrapper(self.mockStoreKit1Wrapper, updatedTransaction: transaction)

        self.mockBackend.stubbedPostReceiptResult = .failure(
            .networkError(.errorResponse(
                .init(code: .internalServerError,
                      originalCode: BackendErrorCode.internalServerError.rawValue,
                      message: "Error",
                      attributeErrors: [:]),
                .internalServerError)
            )
        )

        transaction.mockState = SKPaymentTransactionState.purchased
        self.mockStoreKit1Wrapper.delegate?.storeKit1Wrapper(self.mockStoreKit1Wrapper, updatedTransaction: transaction)

        expect(self.mockBackend.invokedPostReceiptData).to(beTrue())
        expect(self.mockSubscriberAttributesManager.invokedMarkAttributes) == false
    }

}
