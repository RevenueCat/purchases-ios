//
//  LocalizedAlertErrorTests.swift
//
//
//  Created by Nacho Soto on 1/16/24.
//

import Nimble
import RevenueCat
@testable import RevenueCatUI
import StoreKit
import XCTest

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class LocalizedAlertGenericErrorTests: TestCase {

    private static let error = LocalizedAlertError(
        error: StoreKitError.networkError(URLError(.notConnectedToInternet)) as NSError
    )

    func testErrorDescription() {
        expect(Self.error.errorDescription) == "StoreKit.StoreKitError 0"
    }

    func testFailureReason() {
        expect(Self.error.failureReason) == "The operation couldn’t be completed. (NSURLErrorDomain error -1009.)"
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class LocalizedAlertErrorCodeTests: TestCase {

    private static let error = LocalizedAlertError(error: ErrorCode.storeProblemError as NSError)

    func testErrorDescription() {
        expect(Self.error.errorDescription) == "Error"
    }

    func testFailureReason() {
        #if os(macOS) || targetEnvironment(macCatalyst)
        let expected = "Error 2: There was a problem with the App Store. " +
            "This could also indicate the purchase dialog was cancelled."
        #else
        let expected = "Error 2: There was a problem with the App Store."
        #endif
        expect(Self.error.failureReason) == expected
    }

}
