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

class MockBundle: Bundle {
    enum ReceiptURLResult {
        case receiptWithData
        case emptyReceipt
        case sandboxReceipt
        case nilURL
    }

    var receiptURLResult: ReceiptURLResult = .receiptWithData

    private static let mockAppStoreReceiptFileName = "base64encodedreceiptsample1"
    private static let mockSandboxReceiptFileName = "base64encoded_sandboxReceipt"

    override var appStoreReceiptURL: URL? {
        let testBundle = Bundle(for: type(of: self))

        switch self.receiptURLResult {
        case .receiptWithData:
            return testBundle
                .url(forResource: Self.mockAppStoreReceiptFileName, withExtension: "txt")
        case .emptyReceipt:
            return URL(string: "")
        case .sandboxReceipt:
            return testBundle
                .url(forResource: Self.mockSandboxReceiptFileName, withExtension: "txt")
        case .nilURL:
            return nil
        }
    }

}
