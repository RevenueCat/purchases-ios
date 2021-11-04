//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

class MockAttributionFetcher: RCAttributionFetcher {
    
    override func identifierForAdvertisers() -> String? {
        return "rc_idfa"
    }

    override func identifierForVendor() -> String? {
        return "rc_idfv"
    }

    override func afficheClientAttributionDetails(completionBlock completionHandler: @escaping ([String: NSObject]?, Error?) -> Void) {
        completionHandler(["Version3.1": ["iad-campaign-id": 15292426, "iad-attribution": true] as NSObject], nil)
    }
}
