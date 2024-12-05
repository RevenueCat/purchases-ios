//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  BackendPostRedeemWebPurchaseTests.swift
//
//  Created by Antonio Rico Diez on 11/6/24.

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class BackendPostRedeemWebPurchaseTests: BaseBackendTests {

    override func setUpWithError() throws {
        try super.setUpWithError()

        try AvailabilityChecks.iOS15APIAvailableOrSkipTest()
    }

    override func createClient() -> MockHTTPClient {
        super.createClient(#file)
    }

    func testPostRedeemWebPurchaseReturnsCorrectCustomerInfo() {
        self.httpClient.mock(
            requestPath: .postRedeemWebPurchase,
            response: .init(statusCode: .success, response: Self.validCustomerResponse)
        )

        let result = waitUntilValue { completion in
            self.redeemWebPurchaseAPI.postRedeemWebPurchase(appUserID: "test-user-id",
                                                            redemptionToken: "test-redemption-token",
                                                            completion: completion)
        }

        expect(result).to(beSuccess())

        let customerInfo = result?.value
        expect(customerInfo).notTo(beNil())
        expect(self.httpClient.calls.count).to(equal(1))
        let subscription = customerInfo!.subscriber.subscriptions.keys.first
        expect(subscription).to(equal("onemonth_freetrial"))
    }

    func testPostRedeemWebPurchaseReturnsExpectedInvalidTokenError() {
        let backendErrorCode = BackendErrorCode.invalidWebRedemptionToken
        let message = "Invalid token."
        let errorResponse = ErrorResponse(code: backendErrorCode,
                                          originalCode: backendErrorCode.rawValue,
                                          message: message)
        self.httpClient.mock(
            requestPath: .postRedeemWebPurchase,
            response: .init(error: .errorResponse(errorResponse, .forbidden))
        )

        let result = waitUntilValue { completion in
            self.redeemWebPurchaseAPI.postRedeemWebPurchase(appUserID: "test-user-id",
                                                            redemptionToken: "test-redemption-token",
                                                            completion: completion)
        }

        expect(result).to(beFailure())

        let error: PurchasesError? = result?.error?.asPurchasesError
        expect(error?.errorCode).to(equal(ErrorCode.invalidWebPurchaseToken.rawValue))
        expect(error?.localizedDescription).to(equal(
            "The link you provided does not contain a valid purchase token. Invalid token."
        ))
    }

    func testPostRedeemWebPurchaseReturnsPurchaseBelongsToOtherUserError() {
        let backendErrorCode = BackendErrorCode.purchaseBelongsToOtherUser
        let message = "Purchase belongs to other user."
        let errorResponse = ErrorResponse(code: backendErrorCode,
                                          originalCode: backendErrorCode.rawValue,
                                          message: message)
        self.httpClient.mock(
            requestPath: .postRedeemWebPurchase,
            response: .init(error: .errorResponse(errorResponse, .forbidden))
        )

        let result = waitUntilValue { completion in
            self.redeemWebPurchaseAPI.postRedeemWebPurchase(appUserID: "test-user-id",
                                                            redemptionToken: "test-redemption-token",
                                                            completion: completion)
        }

        expect(result).to(beFailure())

        let error: PurchasesError? = result?.error?.asPurchasesError
        expect(error?.errorCode).to(equal(ErrorCode.purchaseBelongsToOtherUser.rawValue))
        expect(error?.localizedDescription).to(equal(
            "The web purchase already belongs to other user. Purchase belongs to other user."
        ))
    }

    func testPostRedeemWebPurchaseReturnsExpiredTokenError() {
        let backendErrorCode = BackendErrorCode.expiredWebRedemptionToken
        let message = "Token expired."
        let errorResponse = ErrorResponse(code: backendErrorCode,
                                          originalCode: backendErrorCode.rawValue,
                                          message: message,
                                          purchaseRedemptionErrorInfo: .init(obfuscatedEmail: "t***@r*****.**m"))
        self.httpClient.mock(
            requestPath: .postRedeemWebPurchase,
            response: .init(error: .errorResponse(errorResponse, .forbidden))
        )

        let result = waitUntilValue { completion in
            self.redeemWebPurchaseAPI.postRedeemWebPurchase(appUserID: "test-user-id",
                                                            redemptionToken: "test-redemption-token",
                                                            completion: completion)
        }

        expect(result).to(beFailure())

        let error: PurchasesError? = result?.error?.asPurchasesError
        expect(error?.errorCode).to(equal(ErrorCode.expiredWebPurchaseToken.rawValue))
        expect(error?.localizedDescription).to(equal(
            "The link you provided has expired. A new one will be sent to the email used to make the purchase." +
            " Token expired."
        ))
        expect(error?.userInfo[ErrorDetails.obfuscatedEmailKey] as? String) == "t***@r*****.**m"
    }
}
