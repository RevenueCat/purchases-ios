//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ArrayExtensionsTests.swift
//
//  Created by Nacho Soto on 2/17/22.

import Nimble
import XCTest

@testable import RevenueCat

class ArrayExtensionsTests: TestCase {

    // MARK: - popFirst

    func testPopFirstWithEmptyArray() {
        var array: [Int] = []

        expect(array.popFirst()).to(beNil())
        expect(array) == []
    }

    func testPopFirstWithOneElement() {
        var array: [Int] = [1]
        let element = array.popFirst()

        expect(element) == 1
        expect(array) == []
    }

    func testPopFirstWithMultipleElements() {
        var array: [Int] = [3, 2, 1]
        let element = array.popFirst()

        expect(element) == 3
        expect(array) == [2, 1]
    }

    // MARK: - onlyElement

    func testOnlyElementWithEmptyArray() {
        expect([Any]().onlyElement).to(beNil())
    }

    func testOnlyElementWithMultipleElements() {
        expect([1, 2].onlyElement).to(beNil())
    }

    func testOnlyElementWithSingleElement() {
        expect([1].onlyElement) == 1
    }

    // MARK: - safeIndex

    func testSafeIndexWithEmptyArray() {
        expect([Any]()[safe: 0]).to(beNil())
        expect([Any]()[safe: 1]).to(beNil())
    }

    func testSafeIndexWithMultipleElements() {
        expect([1, 2][safe: 0]) == 1
        expect([1, 2][safe: 1]) == 2
        expect([1, 2][safe: 3]).to(beNil())
    }

    func testSafeIndexWithSingleElement() {
        expect([1][safe: 0]) == 1
        expect([1][safe: 1]).to(beNil())
    }

    // MARK: - sum

    func testSumEmptyArray() {
        expect([Int]().sum()) == 0
    }

    func testSumSingleElementArray() {
        expect([5].sum()) == 5
    }

    func testSumArrayWithMultipleElements() {
        expect([1, 2, 3].sum()) == 6
    }

}
