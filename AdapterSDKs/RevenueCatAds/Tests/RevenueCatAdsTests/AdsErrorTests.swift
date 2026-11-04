//
//  AdsErrorTests.swift
//
//  Created by RevenueCat.
//

import XCTest

@_spi(Experimental) @testable import RevenueCatAds

final class AdsErrorTests: TestCase {

    func testDescriptionWithoutUnderlyingError() {
        let error = AdsError(code: .noFill, message: "No bid.")

        XCTAssertEqual(error.description, "AdsError(ad_request_no_fill): No bid.")
    }

    func testDescriptionWithUnderlyingError() {
        let underlying = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "boom"])
        let error = AdsError(code: .loadFailed, message: "Load failed.", underlyingError: underlying)

        XCTAssertEqual(error.description, "AdsError(ad_request_load_failed): Load failed. (boom)")
    }

    func testErrorDescriptionIsTheMessage() {
        let error = AdsError(code: .notReady, message: "Not loaded yet.")

        XCTAssertEqual(error.errorDescription, "Not loaded yet.")
        XCTAssertEqual(error.localizedDescription, "Not loaded yet.")
    }

}
