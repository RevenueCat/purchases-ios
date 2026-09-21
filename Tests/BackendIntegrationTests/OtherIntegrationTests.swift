//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  OtherIntegrationTests.swift
//
//  Created by Nacho Soto on 10/10/22.

import Nimble
import OHHTTPStubs
import OHHTTPStubsSwift
@testable import RevenueCat
import StoreKitTest
import XCTest

class OtherIntegrationTests: BaseBackendIntegrationTests {

    private var testSession: SKTestSession!

    override func setUp() async throws {
        // Some tests need to introspect logs during initialization.
        super.initializeLogger()

        if self.testSession == nil {
            try await self.configureTestSession()
        }

        try await super.setUp()
    }

    override func tearDown() async throws {
        HTTPStubs.removeAllStubs()

        try await super.tearDown()
    }

    func configureTestSession() async throws {
        assert(self.testSession == nil, "SKTestSession already configured")

        self.testSession = try SKTestSession(configurationFileNamed: Constants.storeKitConfigFileName)
        self.testSession.resetToDefaultState()
        self.testSession.disableDialogs = true
        self.testSession.clearTransactions()
        if #available(iOS 15.2, *) {
            self.testSession.timeRate = .monthlyRenewalEveryThirtySeconds
        } else {
            self.testSession.timeRate = .oneSecondIsOneDay
        }

        if #available(iOS 15.0, tvOS 15.0, macOS 12.0, watchOS 8.0, *) {
            // Despite calling `SKTestSession.clearTransactions` tests sometimes
            // begin with leftover transactions. This ensures that we remove them
            // to always start with a clean state.
            await self.deleteAllTransactions(session: self.testSession)
        }
    }

    func testGetCustomerInfo() async throws {
        let info = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)
        expect(info.entitlements.all).to(beEmpty())
        expect(info.isLoadedFromCache) == false
        expect(info.originalSource) == .main
        expect(info.isComputedOffline) == false
    }

    func testGetCustomerInfoCaching() async throws {
        let info1 = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)
        expect(info1.isLoadedFromCache) == false
        expect(info1.originalSource) == .main
        expect(info1.isComputedOffline) == false

        self.logger.clearMessages()

        let info2 = try await self.purchases.customerInfo()
        expect(info2.isLoadedFromCache) == true
        expect(info2.originalSource) == .main
        expect(info2.isComputedOffline) == false

        self.logger.verifyMessageWasLogged(Strings.customerInfo.vending_cache, level: .debug)
        try self.logger.verifyMessageWasNotLogged(
            Strings.network.api_request_started(
                .init(method: .get, path: .getCustomerInfo(appUserID: self.purchases.appUserID))
            )
        )
    }

    func testGetOfferingsMultipleTimesInParallel() async throws {
        let requestCount = 3

        let purchases = try self.purchases

        // 1. Invalidate cache
        purchases.invalidateOfferingsCache()
        self.logger.clearMessages()

        // 2. Request offerings multiple times in parallel
        await withThrowingTaskGroup(of: Void.self) {
            for _ in 0..<requestCount {
                $0.addTask { _ = try await purchases.offerings() }
            }
        }

        // 3. Verify N-1 requests were de-duped
        self.logger.verifyMessageWasLogged(
            "Network operation 'GetOfferingsOperation' found with the same cache key",
            level: .debug,
            expectedCount: requestCount - 1
        )
        self.logger.verifyMessageWasLogged(
            Strings.network.api_request_completed(
                .init(method: .get,
                      path: .getOfferings(appUserID: try self.purchases.appUserID)),
                httpCode: .notModified,
                metadata: nil
            ),
            level: .debug,
            expectedCount: 1
        )
    }

    func testCustomerInfoIsOnlyFetchedOnceOnAppLaunch() async throws {
        // 1. Make sure any existing customer info requests finish
        var customerInfoIterator = try? purchases.customerInfoStream.makeAsyncIterator()
        _ = await customerInfoIterator?.next()

        // 2. Verify only one CustomerInfo request was done
        try self.logger.verifyMessageWasLogged(
            Strings.network.api_request_started(
                .init(
                    method: .get,
                    path: .getCustomerInfo(appUserID: self.purchases.appUserID)
                )
            ),
            level: .debug,
            expectedCount: 1
        )
    }

    func testOfferingsAreOnlyFetchedOnceOnAppLaunch() async throws {
        // 1. Make sure any existing offerings requests finish
        _ = try await purchases.offerings()

        // 2. Verify only one Offerings request was done
        try self.logger.verifyMessageWasLogged(
            Strings.network.api_request_started(
                .init(
                    method: .get,
                    path: .getOfferings(appUserID: self.purchases.appUserID)
                )
            ),
            level: .debug,
            expectedCount: 1
        )
    }

    func testGetCustomerInfoReturnsNotModified() async throws {
        // 1. Fetch user once
        _ = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)

        // 2. Re-fetch user
        let info2 = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)

        let expectedRequest = HTTPRequest(method: .get,
                                          path: .getCustomerInfo(appUserID: try self.purchases.appUserID))

        // 3. Verify response was 304
        self.logger.verifyMessageWasLogged(
            Strings.network.api_request_completed(expectedRequest, httpCode: .notModified, metadata: nil)
        )

        expect(info2.isLoadedFromCache) == false
    }

    func testGetCustomerInfoAfterLogInReturnsNotModified() async throws {
        // 1. Log-in to force a new user
        _ = try await self.purchases.logIn(UUID().uuidString)

        // 2. Fetch user once
        _ = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)

        // 3. Re-fetch user
        let info3 = try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent)

        let expectedRequest = HTTPRequest(method: .get,
                                          path: .getCustomerInfo(appUserID: try self.purchases.appUserID))

        // 4. Verify response was 304
        self.logger.verifyMessageWasLogged(
            Strings.network.api_request_completed(expectedRequest, httpCode: .notModified, metadata: nil)
        )

        expect(info3.isLoadedFromCache) == false
    }

    func testAnonymousCustomerInfoArrivingAfterLogInDoesNotReplaceLoggedInUser() async throws {
        // 1. Create an identified user. It gets aliased to the initial anonymous user.
        let identifiedUserID = UUID().uuidString
        _ = try await self.purchases.logIn(identifiedUserID)

        // 2. Log out to create a new anonymous user, which won't be aliased when logging in again.
        _ = try await self.purchases.logOut()
        let anonymousUserID = try self.purchases.appUserID

        // 3. Flush pending subscriber attributes: `logIn` syncs them first, and that request would
        // otherwise be queued ahead of the login request below. Attributes are synced before offerings
        // are fetched, so an offerings error is irrelevant here.
        _ = try? await self.purchases.syncAttributesAndOfferingsIfNeeded()

        // 4. Block the head of the serial request pipeline with a slow, harmless request,
        // so the requests enqueued next run in a known order once it finishes.
        let offeringsPath = HTTPRequest.Path.getOfferings(appUserID: anonymousUserID).relativePath
        stub(
            condition: { $0.url?.absoluteString.hasSuffix(offeringsPath) == true },
            response: { _ in HTTPStubsResponse(data: Data(), statusCode: 400, headers: nil).responseTime(5) }
        )
        try self.purchases.invalidateOfferingsCache()
        try self.purchases.getOfferings(fetchPolicy: .default, fetchCurrent: true) { _, _ in }
        try await self.logger.verifyMessageIsEventuallyLogged(
            Strings.network.starting_request(httpMethod: "GET", path: offeringsPath),
            level: .debug
        )

        // 5. Log in while the pipeline is blocked. The request is queued behind the offerings request.
        let updatesBeforeLogIn = self.purchasesDelegate.receivedCustomerInfos.count
        let logInTask = Task { try await self.purchases.logIn(identifiedUserID) }
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // 6. Fetch CustomerInfo while the anonymous user is still current. The request is created
        // for the anonymous user, but it is queued behind logIn so it only runs after it has completed.
        let anonymousFetchTask = Task { try await self.purchases.customerInfo(fetchPolicy: .fetchCurrent) }

        let (logInInfo, created) = try await logInTask.value
        expect(created) == false
        expect(logInInfo.originalAppUserId) != anonymousUserID
        expect(try self.purchases.appUserID) == identifiedUserID

        let anonymousInfo = try await anonymousFetchTask.value
        expect(anonymousInfo.originalAppUserId) == anonymousUserID

        // Verify the anonymous request only started after logIn completed, otherwise the race was not reproduced.
        let anonymousPath = HTTPRequest.Path.getCustomerInfo(appUserID: anonymousUserID).relativePath
        let logInCompleted = "API request completed: POST '\(HTTPRequest.Path.logIn.relativePath)'"
        let anonymousFetchStarted = Strings.network.starting_request(httpMethod: "GET", path: anonymousPath).description
        let messages = self.logger.messages.map(\.message)
        let logInIndex = try XCTUnwrap(messages.lastIndex { $0.contains(logInCompleted) })
        let anonymousFetchIndex = try XCTUnwrap(messages.lastIndex { $0.contains(anonymousFetchStarted) })
        expect(logInIndex) < anonymousFetchIndex

        // 7. The anonymous CustomerInfo must not have been sent to the delegate after logging in,
        // nor replaced the identified user's cache. Observers are notified asynchronously, so wait a bit.
        try await Task.sleep(nanoseconds: 1_000_000_000)
        let updatesAfterLogIn = self.purchasesDelegate.receivedCustomerInfos
            .dropFirst(updatesBeforeLogIn)
            .map(\.originalAppUserId)
        expect(updatesAfterLogIn).to(contain(logInInfo.originalAppUserId))
        expect(updatesAfterLogIn).toNot(contain(anonymousUserID))
        let cachedInfo = try await self.purchases.customerInfo(fetchPolicy: .fromCacheOnly)
        expect(cachedInfo.originalAppUserId) != anonymousUserID
        expect(try self.purchases.isAnonymous) == false
    }

    func testOfferingsAreOnlyFetchedOnceOnSDKInitialization() async throws {
        self.logger.verifyMessageWasLogged(Strings.offering.offerings_stale_updating_in_foreground,
                                           level: .debug,
                                           expectedCount: 1)
        self.logger.verifyMessageWasLogged("GetOfferingsOperation: Started",
                                           level: .debug,
                                           expectedCount: 1)
    }

    func testHealthRequest() async throws {
        try await self.purchases.healthRequest(signatureVerification: false)
    }

    func testHealthRequestWithVerification() async throws {
        try await self.purchases.healthRequest(signatureVerification: true)
    }

    func testHandledByProductionServer() async throws {
        try await self.purchases.healthRequest(signatureVerification: false)

        self.logger.verifyMessageWasNotLogged(Strings.network.request_handled_by_load_shedder(HTTPRequest.Path.health))
    }

    @available(iOS 15.0, tvOS 15.0, watchOS 8.0, macOS 12.0, *)
    func testProductEntitlementMapping() async throws {
        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()

        let result = try await self.purchases.productEntitlementMapping().entitlementsByProduct
        expect(result).to(haveCount(23))
        expect(result["com.revenuecat.monthly_4.99.1_week_intro"]) == ["premium"]
        expect(result["lifetime"]) == ["premium"]
        expect(result["com.revenuecat.intro_test.monthly.1_week_intro"]).to(beEmpty())
        expect(result["consumable.10_coins"]).to(beEmpty())
        expect(result["com.revenuecat.sampleapp.monthly.12mocommitment:monthly"]) == ["premium"]
        expect(result["com.revenuecat.sampleapp.monthly.12mocommitment"]) == ["super_premium"]
    }

    @available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *)
    func testEnableAdServicesAttributionTokenCollection() async throws {
        try self.purchases.attribution.enableAdServicesAttributionTokenCollection()

        try await self.logger.verifyMessageIsEventuallyLogged(
            Strings.attribution.adservices_token_post_succeeded.description,
            level: .debug,
            timeout: .seconds(10),
            pollInterval: .milliseconds(200)
        )
    }

    func testRequestV1PaywallImages() async throws {
        let offering = try await XCTAsyncUnwrap(try await self.purchases.offerings().all["alternate_offering"])
        let paywall = try XCTUnwrap(offering.paywall)
        let images = paywall.allImageURLs

        expect(images).toNot(beEmpty())

        for imageURL in images {
            let (data, response) = try await URLSession.shared.data(from: imageURL)
            let urlResponse = try XCTUnwrap(response as? HTTPURLResponse)

            expect(data)
                .toNot(
                    beEmpty(),
                    description: "Found empty image: \(imageURL)"
                )
            expect(urlResponse.statusCode)
                .to(
                    equal(200),
                    description: "Unexpected response for image: \(imageURL)"
                )
            expect(urlResponse.value(forHTTPHeaderField: "Content-Type"))
                .to(
                    equal("image/heic"),
                    description: "Unexpected content type for image: \(imageURL)"
                )
        }
    }

    func testDoesntRetryUnsupportedURLPaths() async throws {
        // Ensure that the each time POST /receipt is called, we mock a 429 error
        var stubbedRequestCount = 0
        let host = try XCTUnwrap(HTTPRequest.Path.serverHostURL.host)
        stub(condition: isHost(host) && isPath("/v1/subscribers/identify")) { _ in
            stubbedRequestCount += 1
            return Self.emptyTooManyRequestsResponse()
        }

        do {
            _ = try await self.purchases.logIn(UUID().uuidString)
            fail("Expected purchases.login to fail after not retrying a 429 response")
        } catch {
            expect(error).to(matchError(ErrorCode.unknownError))
        }

        expect(stubbedRequestCount).to(equal(1)) // Just the original request
    }

    // MARK: - Virtual Currencies
    func testGetVirtualCurrenciesWithBalancesOfZero() async throws {
        let appUserIDWith0BalanceCurrencies = "integrationTestUserWithAllBalancesEqualTo0"
        let purchases = try self.purchases

        _ = try await purchases.logIn(appUserIDWith0BalanceCurrencies)

        purchases.invalidateVirtualCurrenciesCache()
        let virtualCurrencies = try await purchases.virtualCurrencies()
        try validateAllZeroBalanceVirtualCurrenciesObject(virtualCurrencies)
    }

    func testGetVirtualCurrenciesWithBalancesWithSomeNonZeroValues() async throws {
        let appUserIDWith0BalanceCurrencies = "integrationTestUserWithAllBalancesNonZero"
        let purchases = try self.purchases

        _ = try await purchases.logIn(appUserIDWith0BalanceCurrencies)

        purchases.invalidateVirtualCurrenciesCache()
        let virtualCurrencies = try await purchases.virtualCurrencies()

        try validateAllNonZeroBalanceVirtualCurrenciesObject(virtualCurrencies)
    }

    func testGetVirtualCurrenciesMultipleTimesInParallel() async throws {
        let requestCount = 3

        let purchases = try self.purchases

        // 1. Invalidate cache
        purchases.invalidateVirtualCurrenciesCache()
        self.logger.clearMessages()

        // 2. Request offerings multiple times in parallel
        await withThrowingTaskGroup(of: Void.self) {
            for _ in 0..<requestCount {
                $0.addTask { _ = try await purchases.virtualCurrencies() }
            }
        }

        // 3. Verify N-1 requests were de-duped
        self.logger.verifyMessageWasLogged(
            "Network operation 'GetVirtualCurrenciesOperation' found with the same cache key",
            level: .debug,
            expectedCount: requestCount - 1
        )

        self.logger.verifyMessageWasLogged(
            Strings.network.api_request_completed(
                .init(method: .get,
                      path: .getVirtualCurrencies(appUserID: try self.purchases.appUserID)),
                httpCode: .success,
                metadata: nil
            ),
            level: .debug,
            expectedCount: 1
        )
    }

    func testGettingVirtualCurrenciesForNewUserReturnsVCsWith0Balance() async throws {
        let newAppUserID = "integrationTestUser_\(UUID().uuidString)"
        let purchases = try self.purchases

        _ = try await purchases.logIn(newAppUserID)

        purchases.invalidateVirtualCurrenciesCache()
        let virtualCurrencies = try await purchases.virtualCurrencies()
        try validateAllZeroBalanceVirtualCurrenciesObject(virtualCurrencies)
    }

    func testCachedVirtualCurrencies() async throws {
        let appUserID = "integrationTestUserWithAllBalancesNonZero"
        let purchases = try self.purchases

        _ = try await purchases.logIn(appUserID)

        purchases.invalidateVirtualCurrenciesCache()
        let virtualCurrencies = try await purchases.virtualCurrencies()
        try validateAllNonZeroBalanceVirtualCurrenciesObject(virtualCurrencies)

        var cachedVirtualCurrencies = purchases.cachedVirtualCurrencies
        try validateAllNonZeroBalanceVirtualCurrenciesObject(cachedVirtualCurrencies)

        purchases.invalidateVirtualCurrenciesCache()
        cachedVirtualCurrencies = purchases.cachedVirtualCurrencies
        expect(cachedVirtualCurrencies).to(beNil())
    }

    private func validateAllZeroBalanceVirtualCurrenciesObject(_ virtualCurrencies: VirtualCurrencies?) throws {
        let virtualCurrencies = try XCTUnwrap(virtualCurrencies)
        expect(virtualCurrencies.all.count).to(equal(3))

        let testCurrency = try XCTUnwrap(virtualCurrencies["TEST"])
        expect(testCurrency.balance).to(equal(0))
        expect(testCurrency.code).to(equal("TEST"))
        expect(testCurrency.name).to(equal("Test Currency"))
        expect(testCurrency.serverDescription).to(equal("This is a test currency"))

        let testCurrency2 = try XCTUnwrap(virtualCurrencies["TEST2"])
        expect(testCurrency2.balance).to(equal(0))
        expect(testCurrency2.code).to(equal("TEST2"))
        expect(testCurrency2.name).to(equal("Test Currency 2"))
        expect(testCurrency2.serverDescription).to(equal("This is test currency 2"))

        let testCurrency3 = try XCTUnwrap(virtualCurrencies["TEST3"])
        expect(testCurrency3.balance).to(equal(0))
        expect(testCurrency3.code).to(equal("TEST3"))
        expect(testCurrency3.name).to(equal("Test Currency 3"))
        expect(testCurrency3.serverDescription).to(beNil())
    }

    private func validateAllNonZeroBalanceVirtualCurrenciesObject(_ virtualCurrencies: VirtualCurrencies?) throws {
        let virtualCurrencies = try XCTUnwrap(virtualCurrencies)
        expect(virtualCurrencies.all.count).to(equal(3))

        let testCurrency = try XCTUnwrap(virtualCurrencies["TEST"])
        expect(testCurrency.balance).to(equal(100))
        expect(testCurrency.code).to(equal("TEST"))
        expect(testCurrency.name).to(equal("Test Currency"))
        expect(testCurrency.serverDescription).to(equal("This is a test currency"))

        let testCurrency2 = try XCTUnwrap(virtualCurrencies["TEST2"])
        expect(testCurrency2.balance).to(equal(777))
        expect(testCurrency2.code).to(equal("TEST2"))
        expect(testCurrency2.name).to(equal("Test Currency 2"))
        expect(testCurrency2.serverDescription).to(equal("This is test currency 2"))

        let testCurrency3 = try XCTUnwrap(virtualCurrencies["TEST3"])
        expect(testCurrency3.balance).to(equal(0))
        expect(testCurrency3.code).to(equal("TEST3"))
        expect(testCurrency3.name).to(equal("Test Currency 3"))
        expect(testCurrency3.serverDescription).to(beNil())
    }
}

private extension OtherIntegrationTests {
    static func emptyTooManyRequestsResponse(
        headers: [String: String]? = nil
    ) -> HTTPStubsResponse {
        // `HTTPStubsResponse` doesn't have value semantics, it's a mutable class!
        // This creates a new response each time so modifications in one test don't affect others.
        return .init(data: Data(),
                     statusCode: 429,
                     headers: headers)
    }
}
