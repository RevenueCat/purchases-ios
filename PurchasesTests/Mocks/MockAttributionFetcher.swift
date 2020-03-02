//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

class MockAttributionFetcher: RCAttributionFetcher {
    var receiptDataCalled = false
    var shouldReturnReceipt = true
    var receiptDataTimesCalled = 0

    override func advertisingIdentifier() -> String? {
        return "rc_idfa"
    }

    override func identifierForVendor() -> String? {
        return "rc_idfv"
    }

    override func adClientAttributionDetails(completionBlock completionHandler: @escaping ([String: NSObject]?, Error?) -> Void) {
        completionHandler(["Version3.1": ["iad-campaign-id": 15292426, "iad-attribution": true] as NSObject], nil)
    }
}
