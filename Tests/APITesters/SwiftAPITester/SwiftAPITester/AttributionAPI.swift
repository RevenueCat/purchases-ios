//
//  AttributionAPI.swift
//  SwiftAPITester
//
//  Created by Joshua Liebowitz on 6/13/22.
//

import Foundation
import RevenueCat

var attribution: Attribution!

func checkAttributionAPI() {
    attribution.setAttributes([String: String]())

    attribution.setEmail("")
    attribution.setEmail(nil)

    attribution.setPhoneNumber("")
    attribution.setPhoneNumber(nil)

    attribution.setDisplayName("")
    attribution.setDisplayName(nil)

    attribution.setPushToken("".data(using: String.Encoding.utf8)!)
    attribution.setPushToken(nil)

    attribution.setPushTokenString("")
    attribution.setPushTokenString(nil)

    attribution.setAdjustID("")
    attribution.setAdjustID(nil)

    attribution.setAppsflyerID("")
    attribution.setAppsflyerID(nil)

    attribution.setFBAnonymousID("")
    attribution.setFBAnonymousID(nil)

    attribution.setMparticleID("")
    attribution.setMparticleID(nil)

    attribution.setOnesignalID("")
    attribution.setOnesignalID(nil)

    attribution.setOnesignalUserID("")
    attribution.setOnesignalUserID(nil)

    attribution.setCleverTapID("")
    attribution.setCleverTapID(nil)

    attribution.setMixpanelDistinctID("")
    attribution.setMixpanelDistinctID(nil)

    attribution.setFirebaseAppInstanceID("")
    attribution.setFirebaseAppInstanceID(nil)

    attribution.setMediaSource("")
    attribution.setMediaSource(nil)

    attribution.setCampaign("")
    attribution.setCampaign(nil)

    attribution.setAdGroup("")
    attribution.setAdGroup(nil)

    attribution.setAd("")
    attribution.setAd(nil)

    attribution.setKeyword("")
    attribution.setKeyword(nil)

    attribution.setCreative("")
    attribution.setCreative(nil)

    attribution.collectDeviceIdentifiers()

    #if !os(tvOS) && !os(watchOS)
    if #available(iOS 14.3, macOS 11.1, macCatalyst 14.3, *) {
        attribution.enableAdServicesAttributionTokenCollection()
    }
    #endif
}
