//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AttributionNetwork.swift
//
//  Created by Joshua Liebowitz on 7/1/21.
//

import Foundation

/**
 Enum of supported attribution networks
 */
@objc(RCAttributionNetwork) public enum AttributionNetwork: Int {

    /**
     Apple's search ads
     */
    @available(*, deprecated, message: "use adServices")
    case appleSearchAds = 0

    /**
     Adjust https://www.adjust.com/
     */
    case adjust = 1

    /**
     AppsFlyer https://www.appsflyer.com/
     */
    case appsFlyer = 2

    /**
     Branch https://www.branch.io/
     */
    case branch = 3

    /**
     Tenjin https://www.tenjin.io/
     */
    case tenjin = 4

    /**
     Facebook https://developers.facebook.com/
     */
    case facebook = 5

    /**
    mParticle https://www.mparticle.com/
    */
    case mParticle = 6

    /**
     AdServices token
     */
    case adServices = 7

}

extension AttributionNetwork: Encodable {

    // swiftlint:disable:next missing_docs
    public func encode(to encoder: Encoder) throws {
        try self.rawValue.encode(to: encoder)
    }

}

extension AttributionNetwork {

    var isAppleSearchAdds: Bool {
        switch self {
        case .appleSearchAds: return true
        default: return false
        }
    }

}
