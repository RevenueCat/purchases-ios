//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

@testable import RevenueCat

class MockAttributionFetcher: AttributionFetcher {

    override var identifierForAdvertisers: String? {
        return "rc_idfa"
    }

    override var identifierForVendor: String? {
        return "rc_idfv"
    }

    override func afficheClientAttributionDetails(
        completion completionHandler: @escaping ([String: NSObject]?, Error?) -> Void
    ) {
        completionHandler(["Version3.1": ["iad-campaign-id": 15292426, "iad-attribution": true] as NSObject], nil)
    }
}
