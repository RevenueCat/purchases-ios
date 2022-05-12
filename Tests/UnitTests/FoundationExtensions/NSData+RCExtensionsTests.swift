//
// Created by RevenueCat on 3/4/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
import Nimble
import XCTest

@testable import RevenueCat

class NSDataExtensionsTests: TestCase {

    func testAsString() {
        let data = Data([
            0xe3, 0x88, 0x15, 0x2d,
            0x6c, 0x67, 0xf4, 0xd5,
            0xf7, 0xa7, 0x8e, 0xdf,
            0x07, 0x39, 0x46, 0xf1,
            0x58, 0x35, 0x7f, 0x89,
            0xa1, 0xdc, 0x74, 0xdf,
            0xf8, 0x0a, 0x79, 0x67,
            0x40, 0xfd, 0x9d, 0x91
        ])

        let nsData = data as NSData

        expect(nsData.asString()) == "e388152d6c67f4d5f7a78edf073946f158357f89a1dc74dff80a796740fd9d91"
    }

    func testAsFetchToken() {
        let receiptFilename = "base64EncodedReceiptSampleForDataExtension"
        let storedReceiptText = NSDataExtensionsTests.readFile(named: receiptFilename)
        let storedReceiptData = NSDataExtensionsTests.sampleReceiptData(receiptName: receiptFilename)
        let fetchToken = storedReceiptData.asFetchToken

        expect(fetchToken).to(equal(storedReceiptText))
        expect(storedReceiptData.asFetchToken).to(equal(storedReceiptText))
    }
}

extension NSDataExtensionsTests {

    static func sampleReceiptData(receiptName: String) -> Data {
        let receiptText = readFile(named: receiptName)
        guard let receiptData = Data(base64Encoded: receiptText) else { fatalError("couldn't decode file") }
        return receiptData
    }

    static func readFile(named filename: String) -> String {
        guard let pathString = Bundle(for: Self.self).path(forResource: filename, ofType: "txt") else {
            fatalError("\(filename) not found")
        }
        do {
            return try String(contentsOfFile: pathString, encoding: String.Encoding.utf8)
        } catch let error {
            fatalError("couldn't read file named \(filename). Error: \(error.localizedDescription)")
        }
    }

}
