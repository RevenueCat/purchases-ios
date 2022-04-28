//
// Created by RevenueCat on 3/2/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

@testable import RevenueCat

class MockAttributionFetcher: AttributionFetcher {

    var adServicesTokenCollectionCalled = false
    var adServicesTokenToReturn: String? = "adServicesToken"

    override var identifierForAdvertisers: String? {
        return "rc_idfa"
    }

    override var identifierForVendor: String? {
        return "rc_idfv"
    }

    override func adServicesToken() -> String? {
        adServicesTokenCollectionCalled = true
        return adServicesTokenToReturn
    }
}
