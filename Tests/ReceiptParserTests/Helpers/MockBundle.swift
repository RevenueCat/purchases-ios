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

final class MockBundle: Bundle {

    enum ReceiptURLResult {

        case appStoreReceipt
        case emptyReceipt
        case sandboxReceipt
        case sandboxReceipt2
        case sandboxReceipt3
        case unsupportedReceipt1
        case unsupportedReceipt2
        case nilURL

    }

    var receiptURLResult: ReceiptURLResult = .appStoreReceipt

    override var appStoreReceiptURL: URL? {
        let testBundle = Bundle(for: Self.self)

        switch self.receiptURLResult {
        case .appStoreReceipt:
            return testBundle
                .url(forResource: Self.mockAppStoreReceiptFileName, withExtension: "txt")
        case .emptyReceipt:
            return URL(string: "")
        case .sandboxReceipt:
            return testBundle
                .url(forResource: Self.mockSandboxReceiptFileName, withExtension: "txt")
        case .sandboxReceipt2:
            return testBundle
                .url(forResource: Self.mockSandboxReceiptFileName2, withExtension: "txt")
        case .sandboxReceipt3:
            return testBundle
                .url(forResource: Self.mockSandboxReceiptFileName3, withExtension: "txt")
        case .unsupportedReceipt1:
            return testBundle
                .url(forResource: Self.mockUnsupportedReceiptFileName1, withExtension: "txt")
        case .unsupportedReceipt2:
            return testBundle
                .url(forResource: Self.mockUnsupportedReceiptFileName2, withExtension: "txt")
        case .nilURL:
            return nil
        }
    }

    // MARK: -

    private static let mockAppStoreReceiptFileName = "base64encodedreceiptsample1"
    private static let mockSandboxReceiptFileName = "base64encoded_sandboxReceipt"
    private static let mockSandboxReceiptFileName2 = "base64encoded_sandboxReceipt2"
    private static let mockSandboxReceiptFileName3 = "base64encoded_sandboxReceipt3"
    private static let mockUnsupportedReceiptFileName1 = "base64encoded_unsupportedReceipt1"
    private static let mockUnsupportedReceiptFileName2 = "base64encoded_unsupportedReceipt2"

}

extension MockBundle: @unchecked Sendable {}
