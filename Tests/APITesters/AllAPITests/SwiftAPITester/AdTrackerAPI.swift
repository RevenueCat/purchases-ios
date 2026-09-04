//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AdTrackerAPI.swift
//

import Foundation
import RevenueCat

func checkAdTrackerAPI() {
    if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
        let adTracker: AdTracker = Purchases.shared.adTracker

        let mediatorName: MediatorName = MediatorName(rawValue: "")
        let _: MediatorName = .adMob
        let _: MediatorName = .appLovin
        let _: String = mediatorName.rawValue

        let adFormat: AdFormat = AdFormat(rawValue: "")
        let _: AdFormat = .other
        let _: AdFormat = .banner
        let _: AdFormat = .interstitial
        let _: AdFormat = .rewarded
        let _: AdFormat = .rewardedInterstitial
        let _: AdFormat = .native
        let _: AdFormat = .appOpen
        let _: String = adFormat.rawValue

        let precision: AdRevenue.Precision = AdRevenue.Precision(rawValue: "")
        let _: AdRevenue.Precision = .exact
        let _: AdRevenue.Precision = .publisherDefined
        let _: AdRevenue.Precision = .estimated
        let _: AdRevenue.Precision = .unknown
        let _: String = precision.rawValue

        let failedToLoad: AdFailedToLoad = AdFailedToLoad(
            mediatorName: mediatorName,
            adFormat: adFormat,
            placement: nil,
            adUnitId: "",
            mediatorErrorCode: nil
        )
        let _: AdFailedToLoad = AdFailedToLoad(
            mediatorName: mediatorName,
            adFormat: adFormat,
            adUnitId: "",
            mediatorErrorCode: 0
        )
        let _: MediatorName = failedToLoad.mediatorName
        let _: AdFormat = failedToLoad.adFormat
        let _: String? = failedToLoad.placement
        let _: String = failedToLoad.adUnitId
        let _: Int? = failedToLoad.mediatorErrorCode
        adTracker.trackAdFailedToLoad(failedToLoad)

        let loaded: AdLoaded = AdLoaded(
            networkName: nil,
            mediatorName: mediatorName,
            adFormat: adFormat,
            placement: nil,
            adUnitId: "",
            impressionId: ""
        )
        let _: AdLoaded = AdLoaded(
            networkName: "",
            mediatorName: mediatorName,
            adFormat: adFormat,
            adUnitId: "",
            impressionId: ""
        )
        let _: String? = loaded.networkName
        let _: MediatorName = loaded.mediatorName
        let _: AdFormat = loaded.adFormat
        let _: String? = loaded.placement
        let _: String = loaded.adUnitId
        let _: String = loaded.impressionId
        adTracker.trackAdLoaded(loaded)

        let displayed: AdDisplayed = AdDisplayed(
            networkName: nil,
            mediatorName: mediatorName,
            adFormat: adFormat,
            placement: nil,
            adUnitId: "",
            impressionId: ""
        )
        let _: AdDisplayed = AdDisplayed(
            networkName: "",
            mediatorName: mediatorName,
            adFormat: adFormat,
            adUnitId: "",
            impressionId: ""
        )
        let _: String? = displayed.networkName
        let _: MediatorName = displayed.mediatorName
        let _: AdFormat = displayed.adFormat
        let _: String? = displayed.placement
        let _: String = displayed.adUnitId
        let _: String = displayed.impressionId
        adTracker.trackAdDisplayed(displayed)

        let opened: AdOpened = AdOpened(
            networkName: nil,
            mediatorName: mediatorName,
            adFormat: adFormat,
            placement: nil,
            adUnitId: "",
            impressionId: ""
        )
        let _: AdOpened = AdOpened(
            networkName: "",
            mediatorName: mediatorName,
            adFormat: adFormat,
            adUnitId: "",
            impressionId: ""
        )
        let _: String? = opened.networkName
        let _: MediatorName = opened.mediatorName
        let _: AdFormat = opened.adFormat
        let _: String? = opened.placement
        let _: String = opened.adUnitId
        let _: String = opened.impressionId
        adTracker.trackAdOpened(opened)

        let revenue: AdRevenue = AdRevenue(
            networkName: nil,
            mediatorName: mediatorName,
            adFormat: adFormat,
            placement: nil,
            adUnitId: "",
            impressionId: "",
            revenueMicros: 0,
            currency: "",
            precision: precision
        )
        let _: AdRevenue = AdRevenue(
            networkName: "",
            mediatorName: mediatorName,
            adFormat: adFormat,
            adUnitId: "",
            impressionId: "",
            revenueMicros: 0,
            currency: "",
            precision: precision
        )
        let _: String? = revenue.networkName
        let _: MediatorName = revenue.mediatorName
        let _: AdFormat = revenue.adFormat
        let _: String? = revenue.placement
        let _: String = revenue.adUnitId
        let _: String = revenue.impressionId
        let _: Int = revenue.revenueMicros
        let _: String = revenue.currency
        let _: AdRevenue.Precision = revenue.precision
        adTracker.trackAdRevenue(revenue)
    }
}
