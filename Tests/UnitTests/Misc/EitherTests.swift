//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EitherTests.swift
//
//  Created by Nacho Soto on 10/10/22.

import Nimble
import XCTest

@testable import RevenueCat

class EitherTests: TestCase {

    func testLeft() throws {
        let either: Either<Int, String> = .left(1)
        expect(either.left) == 1
        expect(either.right).to(beNil())
    }

    func testRight() throws {
        let either: Either<Int, String> = .right("a")
        expect(either.left).to(beNil())
        expect(either.right) == "a"
    }

}
