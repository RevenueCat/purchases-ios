//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockAsyncSequence.swift
//
//  Created by Nacho Soto on 2/6/23.

import Foundation

final class MockAsyncSequence<Element>: AsyncSequence, AsyncIteratorProtocol {

    private var elements: [Element]

    init(with elements: [Element]) {
        self.elements = elements.reversed()
    }

    func next() async -> Element? {
        return self.getNextElement()
    }

    func makeAsyncIterator() -> MockAsyncSequence {
        return self
    }

    private func getNextElement() -> Element? {
        return self.elements.popLast()
    }

}
