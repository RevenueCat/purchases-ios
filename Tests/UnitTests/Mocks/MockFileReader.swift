//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockFileReader.swift
//
//  Created by Nacho Soto on 1/10/23.

@testable import RevenueCat

final class MockFileReader: FileReader {

    enum Error: Swift.Error {
        case noMockedData
        case emptyMockedData
    }

    var mockedURLContents: [URL: [Data?]] = [:]

    func mock(url: URL, with data: Data) {
        self.mockedURLContents[url] = [data]
    }

    var invokedContentsOfURL: [URL: Int] = [:]

    func contents(of url: URL) throws -> Data {
        let previouslyInvokedContentsOfURL = self.invokedContentsOfURL[url] ?? 0

        self.invokedContentsOfURL[url, default: 0] += 1

        guard let mockedData = self.mockedURLContents[url] else { throw Error.noMockedData }

        if mockedData.isEmpty {
            throw Error.emptyMockedData
        } else if let data = mockedData.onlyElement {
            return try data.orThrow(Error.noMockedData)
        } else {
            return try mockedData[previouslyInvokedContentsOfURL].orThrow(Error.noMockedData)
        }
    }

}
