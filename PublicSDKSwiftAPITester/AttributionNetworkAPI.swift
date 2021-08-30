//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AttributionNetworkAPI.swift
//
//  Created by Madeline Beyl on 8/25/21.

import Foundation
import Purchases

func checkRCAttributionNetworkEnums() {
    var aNetwork: AttributionNetwork = AttributionNetwork.appleSearchAds
    aNetwork = AttributionNetwork.adjust
    aNetwork = AttributionNetwork.appsFlyer
    aNetwork = AttributionNetwork.branch
    aNetwork = AttributionNetwork.tenjin
    aNetwork = AttributionNetwork.facebook
    aNetwork = AttributionNetwork.mParticle

    print(aNetwork)
}
