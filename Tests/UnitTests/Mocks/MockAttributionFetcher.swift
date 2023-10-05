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

    var adServicesTokenCollectionCalled = false
    var adServicesTokenToReturn: String? = "mockAdServicesToken"

    @available(iOS 14.3, tvOS 14.3, macOS 11.1, watchOS 6.2, macCatalyst 14.3, *)
    override var adServicesToken: String? {
        // Note: this needs to be `async` to avoid a crash
        // See https://github.com/apple/swift/issues/68998
        get async {
            self.adServicesTokenCollectionCalled = true
            return self.adServicesTokenToReturn
        }
    }

}
