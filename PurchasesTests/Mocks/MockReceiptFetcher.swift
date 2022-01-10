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

    override func receiptData(refreshPolicy: ReceiptRefreshPolicy, completion: @escaping ((Data?) -> Void)) {
        receiptDataReceivedRefreshPolicy = refreshPolicy
        receiptDataCalled = true
        receiptDataTimesCalled += 1
        if shouldReturnReceipt {
            if shouldReturnZeroBytesReceipt {
                completion(Data())
            } else {
                completion(Data(1...3))
            }
        } else {
            completion(nil)
        }
    }

}
