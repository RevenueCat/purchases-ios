//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockBundle.swift
//
//  Created by Andrés Boedo on 3/8/21.

import Foundation

@testable import RevenueCat

final class MockBundle: Bundle {

    enum ReceiptURLResult {

        case receiptWithData
        case emptyReceipt
        case sandboxReceipt
        case macOSAppStoreReceipt
        case macOSSandboxReceipt
        case nilURL

    }

    var receiptURLResult: ReceiptURLResult = .receiptWithData

    override var appStoreReceiptURL: URL? {
        let testBundle = Bundle(for: Self.self)

        switch self.receiptURLResult {
        case .receiptWithData:
            return testBundle
                .url(forResource: Self.mockAppStoreReceiptFileName, withExtension: "txt")
        case .emptyReceipt:
            return URL(string: "")
        case .sandboxReceipt:
            return testBundle
                .url(forResource: Self.mockSandboxReceiptFileName, withExtension: "txt")
        case .macOSSandboxReceipt:
            // swiftlint:disable:next line_length
            return URL(string: "/Users/nachosoto/Library/Developer/Xcode/DerivedData/PurchaseTester-coxthvoqhbhicvcmwbbwnogtdrle/Build/Products/Debug-maccatalyst/PurchaseTester.app/Contents/_MASReceipt/receipt")!
        case .macOSAppStoreReceipt:
            return URL(string: "/Applications/PurchaseTester.app/Contents/_MASReceipt/receipt")!
        case .nilURL:
            return nil
        }
    }

    // MARK: -

    private static let mockAppStoreReceiptFileName = "base64encodedreceiptsample1"
    private static let mockSandboxReceiptFileName = "base64encoded_sandboxReceipt"

}

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
