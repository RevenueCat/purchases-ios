//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebCheckoutSheetOutcomeTests.swift
//
//  Created by Antonio Pallares on 7/9/26.
//

@testable import RevenueCatUI
import XCTest

#if os(iOS) && canImport(WebKit)

final class WebCheckoutSheetOutcomeTests: TestCase {

    func testReportsTheStatusThePageReturnedWith() {
        XCTAssertEqual(WebCheckoutSheetOutcome(returnedStatus: .success), .returned(.success))
        XCTAssertEqual(WebCheckoutSheetOutcome(returnedStatus: .cancel), .returned(.cancel))
    }

    func testTreatsASheetThatWentWithoutAStatusAsDismissedByTheCustomer() {
        XCTAssertEqual(WebCheckoutSheetOutcome(returnedStatus: nil), .dismissed)
    }

}

#endif
