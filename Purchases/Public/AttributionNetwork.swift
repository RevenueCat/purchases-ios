//
//  AttributionNetwork.swift
//  Purchases
//
//  Created by Joshua Liebowitz on 7/1/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

@objc(RCAttributionNetwork) public enum AttributionNetwork: Int {
    /**
     Apple's search ads
     */
    case appleSearchAds
    /**
     Adjust https://www.adjust.com/
     */
    case adjust
    /**
     AppsFlyer https://www.appsflyer.com/
     */
    case appsFlyer
    /**
     Branch https://www.branch.io/
     */
    case branch
    /**
     Tenjin https://www.tenjin.io/
     */
    case tenjin
    /**
     Facebook https://developers.facebook.com/
     */
    case facebook
    /**
    mParticle https://www.mparticle.com/
    */
    case mParticle
}
