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
import RevenueCat

var aNetwork: AttributionNetwork!
func checkAttributionNetworkEnums() {
    switch aNetwork! {
    case .appleSearchAds,
         .adjust,
         .appsFlyer,
         .branch,
         .tenjin,
         .facebook,
         .mParticle,
         .adServices:
        print(aNetwork!)

    @unknown default: fatalError()
    }
}
