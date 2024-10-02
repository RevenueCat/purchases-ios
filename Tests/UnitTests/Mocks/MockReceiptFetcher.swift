//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockReceiptFetcher.swift
//

@testable import RevenueCat

class MockReceiptFetcher: ReceiptFetcher {

    var receiptDataCalled = false
    var shouldReturnReceipt = true
    var shouldReturnZeroBytesReceipt = false
    var receiptDataTimesCalled = 0
    var receiptDataReceivedRefreshPolicy: ReceiptRefreshPolicy?
    var mockReceiptData: Data = .init(1...3)
    var mockReceiptURL: URL?

    override func receiptData(refreshPolicy: ReceiptRefreshPolicy, completion: @escaping ((Data?, URL?) -> Void)) {
        self.receiptDataReceivedRefreshPolicy = refreshPolicy
        self.receiptDataCalled = true
        self.receiptDataTimesCalled += 1
        if self.shouldReturnReceipt {
            if self.shouldReturnZeroBytesReceipt {
                completion(Data(), self.mockReceiptURL)
            } else {
                completion(self.mockReceiptData, self.mockReceiptURL)
            }
        } else {
            completion(nil, self.mockReceiptURL)
        }
    }

}

extension MockReceiptFetcher: @unchecked Sendable {}
