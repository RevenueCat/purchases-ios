//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

@testable import RevenueCat

class MockAttributionFetcher: AttributionFetcher {

    var adServicesTokenCollected = false

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

    @available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *)
    override func adServicesToken() -> String? {
        adServicesTokenCollected = true
        return "test"
    }
}
