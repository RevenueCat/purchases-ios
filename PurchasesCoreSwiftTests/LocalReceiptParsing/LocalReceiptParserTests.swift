//
//  LocalReceiptParserTests.swift
//  PurchasesTests
//
//  Created by Andrés Boedo on 7/1/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Nimble
import XCTest
@testable import PurchasesCoreSwift

class LocalReceiptParserTests: XCTestCase {
    func testCanInitialize() {
        expect { LocalReceiptParser() } .notTo(raiseException())
    }
}
