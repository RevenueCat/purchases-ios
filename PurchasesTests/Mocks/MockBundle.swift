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
    enum MockAppStoreReceiptURLResult {
        case receiptWithData, emptyReceipt, nilURL
    }
    
    var mockAppStoreReceiptURLResult: MockAppStoreReceiptURLResult = .receiptWithData
    
    private let mockAppStoreReceiptFileName = "base64encodedreceiptsample1"
    
    override var appStoreReceiptURL: URL? {
        switch mockAppStoreReceiptURLResult {
        case .receiptWithData:
            return Bundle(for: type(of: self))
                .url(forResource: mockAppStoreReceiptFileName, withExtension: "txt")
        case .emptyReceipt:
            return URL(string: "")
        case .nilURL:
            return nil
        }
    }
    
}
