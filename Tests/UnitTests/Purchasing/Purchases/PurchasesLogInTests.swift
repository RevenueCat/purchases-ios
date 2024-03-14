//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchasesLogInTests.swift
//
//  Created by Nacho Soto on 8/15/22.

import Nimble
import StoreKit
import XCTest

@testable import RevenueCat

class BasePurchasesLogInTests: BasePurchasesTests {}

class PurchasesLogInTests: BasePurchasesLogInTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.setupAnonPurchases()
    }

    func testLogInWithSuccess() {
        let created: Bool = .random()

        self.identityManager.mockLogInResult = .success((Self.mockLoggedInInfo, created))

        let result = waitUntilValue { completed in
            self.purchases.logIn(Self.appUserID) { customerInfo, created, error in
                completed(Self.logInResult(customerInfo, created, error))
            }
        }

        expect(result).to(beSuccess())
        expect(result?.value) == (Self.mockLoggedInInfo, created)
        expect(self.identityManager.invokedLogInCount) == 1
        expect(self.identityManager.invokedLogInParametersList) == [Self.appUserID]
    }

    func testLogInWithFailure() {
        let error: BackendError = .networkError(.offlineConnection())
        self.identityManager.mockLogInResult = .failure(error)

        let result = waitUntilValue { completed in
            self.purchases.logIn(Self.appUserID) { customerInfo, created, error in
                completed(Self.logInResult(customerInfo, created, error))
            }
        }

        expect(result).to(beFailure())
        expect(result?.error).to(matchError(error.asPurchasesError))
        expect(self.identityManager.invokedLogInCount) == 1
        expect(self.identityManager.invokedLogInParametersList) == [Self.appUserID]
    }

    func testLogOutWithSuccess() {
        self.identityManager.mockLogOutError = nil
        self.backend.overrideCustomerInfoResult = .success(Self.mockLoggedOutInfo)

        expect(self.backend.getCustomerInfoCallCount).toEventually(equal(1))

        let result = waitUntilValue { completed in
            self.purchases.logOut { customerInfo, error in
                completed(Result(customerInfo, error))
            }
        }

        expect(result).to(beSuccess())
        expect(result?.value) == Self.mockLoggedOutInfo

        expect(self.backend.getCustomerInfoCallCount) == 2
        expect(self.identityManager.invokedLogOutCount) == 1
    }

    func testLogOutWithFailure() {
        let error = BackendError.networkError(.offlineConnection()).asPurchasesError
        self.identityManager.mockLogOutError = error

        expect(self.backend.getCustomerInfoCallCount).toEventually(
            equal(1),
            description: "Initial cache update should take place"
        )

        let result = waitUntilValue { completed in
            self.purchases.logOut { customerInfo, error in
                completed(Result(customerInfo, error))
            }
        }

        expect(result).to(beFailure())
        expect(result?.error).to(matchError(error))

        expect(self.backend.getCustomerInfoCallCount).to(
            equal(1),
            description: "Customer info should not have been updated"
        )
        expect(self.identityManager.invokedLogOutCount) == 1
    }

    // MARK: - Switch user

    func testSwitchUserSwitchesUser() {
        self.systemInfo = MockSystemInfo(finishTransactions: true, customEntitlementsComputation: true)
        Purchases.clearSingleton()
        self.initializePurchasesInstance(appUserId: "old-test-user-id")

        self.purchases.internalSwitchUser(to: "test-user-id")

        expect(self.identityManager.invokedSwitchUser) == true
        expect(self.identityManager.invokedSwitchUserParametersList) == ["test-user-id"]
    }

    func testSwitchUserRefreshesOfferingsCache() {
        self.systemInfo = MockSystemInfo(finishTransactions: true, customEntitlementsComputation: true)
        Purchases.clearSingleton()
        self.initializePurchasesInstance(appUserId: "old-test-user-id")

        let baselineOfferingsCallCount = self.mockOfferingsManager.invokedUpdateOfferingsCacheCount

        self.purchases.internalSwitchUser(to: "test-user-id")

        expect(self.mockOfferingsManager.invokedUpdateOfferingsCacheCount) == baselineOfferingsCallCount + 1
    }

    func testSwitchUserNoOpIfAppUserIDIsSameAsCurrent() {
        self.systemInfo = MockSystemInfo(finishTransactions: true, customEntitlementsComputation: true)
        Purchases.clearSingleton()
        let appUserId = "test-user-id"
        self.initializePurchasesInstance(appUserId: appUserId)

        let baselineOfferingsCallCount = self.mockOfferingsManager.invokedUpdateOfferingsCacheCount
        self.identityManager.mockAppUserID = appUserId
        self.identityManager.mockIsAnonymous = false
        self.purchases.internalSwitchUser(to: appUserId)

        expect(self.identityManager.invokedSwitchUser) == false
        expect(self.mockOfferingsManager.invokedUpdateOfferingsCacheCount) == baselineOfferingsCallCount
    }

    // MARK: - Update offerings cache

    func testLogInUpdatesOfferingsCache() throws {
        let isAppBackgrounded: Bool = .random()

        self.systemInfo.stubbedIsApplicationBackgrounded = isAppBackgrounded

        self.identityManager.mockAppUserID = Self.mockLoggedInInfo.originalAppUserId
        self.identityManager.mockIsAnonymous = false
        self.identityManager.mockLogInResult = .success((Self.mockLoggedInInfo, true))

        expect(self.mockOfferingsManager.invokedUpdateOfferingsCacheCount) == 1

        waitUntil { completed in
            self.purchases.logIn(Self.appUserID) { _, _, _ in
                completed()
            }
        }

        expect(self.mockOfferingsManager.invokedUpdateOfferingsCacheCount) == 2

        let parameters = try XCTUnwrap(self.mockOfferingsManager.invokedUpdateOfferingsCacheParameters)
        expect(parameters.appUserID) == Self.mockLoggedInInfo.originalAppUserId
        expect(parameters.isAppBackgrounded) == isAppBackgrounded
    }

    func testLogInFailureDoesNotUpdateOfferingsCache() {
        self.identityManager.mockLogInResult = .failure(.networkError(.offlineConnection()))

        expect(self.mockOfferingsManager.invokedUpdateOfferingsCacheCount) == 1

        waitUntil { completed in
            self.purchases.logIn(Self.appUserID) { _, _, _ in
                completed()
            }
        }

        expect(self.mockOfferingsManager.invokedUpdateOfferingsCacheCount) == 1
    }

    // MARK: - StaticString appUserID

    func testLogInWithStringDoesNotLogMessage() async throws {
        let appUserID = "user ID"

        self.identityManager.mockLogInResult = .success((Self.mockLoggedInInfo, true))

        _ = try await self.purchases.logIn(appUserID)

        self.logger.verifyMessageWasNotLogged(Strings.identity.logging_in_with_static_string,
                                              allowNoMessages: true)
    }

    func testLogInWithStaticStringLogsMessage() async throws {
        self.identityManager.mockLogInResult = .success((Self.mockLoggedInInfo, true))

        _ = try await self.purchases.logIn("Static string")

        self.logger.verifyMessageWasLogged(Strings.identity.logging_in_with_static_string, level: .warn)
    }

    func testCompletionBlockLogInWithStringDoesNotLogMessage() {
        let appUserID = "user ID"

        self.identityManager.mockLogInResult = .success((Self.mockLoggedInInfo, true))

        waitUntil { completed in
            self.purchases.logIn(appUserID) { _, _, _ in
                completed()
            }
        }

        self.logger.verifyMessageWasNotLogged(Strings.identity.logging_in_with_static_string)
    }

    @available(*, deprecated)
    func testCompletionBlockLogInWithStaticStringLogsMessage() {
        self.identityManager.mockLogInResult = .success((Self.mockLoggedInInfo, true))

        waitUntil { completed in
            self.purchases.logIn("Static string") { _, _, _ in
                completed()
            }
        }

        self.logger.verifyMessageWasLogged(Strings.identity.logging_in_with_static_string, level: .warn)
    }

}

class ExistingUserPurchasesLogInTests: BasePurchasesLogInTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.deviceCache.cachedCustomerInfo[Self.appUserID] = try Self.mockLoggedOutInfo.jsonEncodedData
        self.initializePurchasesInstance(appUserId: Self.appUserID)

        expect(self.purchasesDelegate.customerInfo).toEventuallyNot(beNil())
    }

    func testLogInClearsTrialEligibilityCache() {
        // set up updates customer info, which clears cache once. wait until it's done before checking the rest.
        expect(self.cachingTrialOrIntroPriceEligibilityChecker.invokedClearCacheCount).toEventually(equal(1))

        self.identityManager.mockLogInResult = .success((Self.mockLoggedInInfo, true))
        let newAppUserID = "newAppUserID"

        waitUntil { completed in
            self.purchases.logIn(newAppUserID) { customerInfo, _, _ in
                // since we're using a mocked identity manager, we need to manually call
                // customer info manager to update the customer info and trigger an actual
                // call in the monitorChanges observation
                self.customerInfoManager.cache(customerInfo: customerInfo!, appUserID: newAppUserID)
                completed()
            }
        }

        expect(self.cachingTrialOrIntroPriceEligibilityChecker.invokedClearCacheCount).toEventually(equal(2))
    }

    func testLogInClearsPurchasedProductsFetcherCache() {
        // set up updates customer info, which clears cache once. wait until it's done before checking the rest.
        expect(self.mockPurchasedProductsFetcher.invokedClearCacheCount).toEventually(equal(1))

        self.identityManager.mockLogInResult = .success((Self.mockLoggedInInfo, true))
        let newAppUserID = "newAppUserID"

        waitUntil { completed in
            self.purchases.logIn(newAppUserID) { customerInfo, _, _ in
                // since we're using a mocked identity manager, we need to manually call
                // customer info manager to update the customer info and trigger an actual
                // call in the monitorChanges observation
                self.customerInfoManager.cache(customerInfo: customerInfo!, appUserID: newAppUserID)
                completed()
            }
        }

        expect(self.mockPurchasedProductsFetcher.invokedClearCacheCount).toEventually(equal(2))
    }

}

// MARK: -

private extension BasePurchasesLogInTests {

    typealias LogInResult = Result<(customerInfo: CustomerInfo, created: Bool), PublicError>
    typealias LogOutResult = Result<CustomerInfo, PublicError>

    // swiftlint:disable force_try
    static let mockLoggedInInfo = try! CustomerInfo(data: PurchasesLogInTests.loggedInCustomerInfoData)
    static let mockLoggedOutInfo = try! CustomerInfo(data: PurchasesLogInTests.loggedOutCustomerInfoData)
    // swiftlint:enable force_try

    private static let loggedInCustomerInfoData: [String: Any] = [
        "request_date": "2019-08-16T10:30:42Z",
        "subscriber": [
            "first_seen": "2019-07-17T00:05:54Z",
            "original_app_user_id": "user",
            "subscriptions": [:] as [String: Any],
            "other_purchases": [:] as [String: Any],
            "original_application_version": NSNull()
        ] as [String: Any]
    ]

    private static let loggedOutCustomerInfoData: [String: Any] = [
        "request_date": "2019-08-16T10:30:42Z",
        "subscriber": [
            "first_seen": "2019-07-17T00:05:54Z",
            "original_app_user_id": "$RCAnonymousID:5b6fdbad3a0c4f879e43d269ecdf9ba1",
            "subscriptions": [:] as [String: Any],
            "other_purchases": [:] as [String: Any],
            "original_application_version": NSNull()
        ] as [String: Any]
    ]

    /// Converts the result of `Purchases.logIn` into `LogInResult`
    static func logInResult(_ info: CustomerInfo?, _ created: Bool, _ error: PublicError?) -> LogInResult {
        return .init(info.map { ($0, created) }, error)
    }

}
