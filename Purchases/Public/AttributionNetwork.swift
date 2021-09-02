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
