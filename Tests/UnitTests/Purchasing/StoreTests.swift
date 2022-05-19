//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreTests.swift
//
//  Created by Nacho Soto on 5/10/22.

import Nimble
@testable import RevenueCat
import XCTest

class StoreTests: TestCase {

    func testCodable() throws {
        for store in Store.allCases {
            expect(try store.encodeAndDecode()) == store
        }
    }

    func testUnknownStringThrows() throws {
        expect(try Store.decode("\"invalid\"")).to(throwError(errorType: CodableError.self))
    }

    func testNullBecomesUnknown() throws {
        expect(try Store.decode("null")) == .unknownStore
    }

}
