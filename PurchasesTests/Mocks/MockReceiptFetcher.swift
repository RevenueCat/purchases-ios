//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

@testable import PurchasesCoreSwift

class MockReceiptFetcher: ReceiptFetcher {
    var receiptDataCalled = false
    var shouldReturnReceipt = true
    var shouldReturnZeroBytesReceipt = false
    var receiptDataTimesCalled = 0
    var receiptDataReceivedRefreshPolicy: ReceiptRefreshPolicy?

    convenience init(requestFetcher: StoreKitRequestFetcher) {
        self.init(requestFetcher: requestFetcher, bundle: .main)
    }

    @objc override public func receiptData(refreshPolicy: ReceiptRefreshPolicy,
                                           completion: @escaping ((Data?) -> Void)) {
        receiptDataReceivedRefreshPolicy = refreshPolicy
        receiptDataCalled = true
        receiptDataTimesCalled += 1
        if (shouldReturnReceipt) {
            if (shouldReturnZeroBytesReceipt) {
                completion(Data())
            } else {
                completion(Data(1...3))
            }
        } else {
            completion(nil)
        }
    }
}
