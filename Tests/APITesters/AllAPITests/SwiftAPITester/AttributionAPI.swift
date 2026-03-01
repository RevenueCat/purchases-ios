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

    attribution.setAirbridgeDeviceID("")
    attribution.setAirbridgeDeviceID(nil)

    attribution.setKochavaDeviceID("")
    attribution.setKochavaDeviceID(nil)

    attribution.setSolarEngineDistinctId("")
    attribution.setSolarEngineDistinctId(nil)

    attribution.setSolarEngineAccountId("")
    attribution.setSolarEngineAccountId(nil)

    attribution.setSolarEngineVisitorId("")
    attribution.setSolarEngineVisitorId(nil)

    attribution.setMixpanelDistinctID("")
    attribution.setMixpanelDistinctID(nil)

    attribution.setFirebaseAppInstanceID("")
    attribution.setFirebaseAppInstanceID(nil)

    attribution.setTenjinAnalyticsInstallationID("")
    attribution.setTenjinAnalyticsInstallationID(nil)

    attribution.setPostHogUserID("")
    attribution.setPostHogUserID(nil)

    attribution.setAmplitudeUserID("")
    attribution.setAmplitudeUserID(nil)

    attribution.setAmplitudeDeviceID("")
    attribution.setAmplitudeDeviceID(nil)

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

    checkSetAppsFlyerConversionDataAPI()
    checkSetAppstackAttributionParamsAPI()
}

func checkSetAppstackAttributionParamsAPI() {
    attribution.setAppstackAttributionParams(nil) { _, _ in }

    let anyHashableDict: [AnyHashable: Any] = [:]
    attribution.setAppstackAttributionParams(anyHashableDict) { _, _ in }

    let optionalAnyHashableDict: [AnyHashable: Any]? = [:]
    attribution.setAppstackAttributionParams(optionalAnyHashableDict) { _, _ in }

    let stringAnyDict: [String: Any] = [:]
    attribution.setAppstackAttributionParams(stringAnyDict) { _, _ in }

    let stringStringDict: [String: String] = [:]
    attribution.setAppstackAttributionParams(stringStringDict as [AnyHashable: Any]) { _, _ in }

    let stringOptionalStringDict: [String: String?] = [:]
    attribution.setAppstackAttributionParams(
        stringOptionalStringDict.mapValues { $0 as Any } as [AnyHashable: Any]
    ) { _, _ in }

    let stringIntDict: [String: Int] = [:]
    attribution.setAppstackAttributionParams(stringIntDict as [AnyHashable: Any]) { _, _ in }

    let stringOptionalIntDict: [String: Int?] = [:]
    attribution.setAppstackAttributionParams(
        stringOptionalIntDict.mapValues { $0 as Any } as [AnyHashable: Any]
    ) { _, _ in }

    let nsDictionary: NSDictionary = [:]
    attribution.setAppstackAttributionParams(nsDictionary as? [AnyHashable: Any]) { _, _ in }
}

func checkSetAppsFlyerConversionDataAPI() {
    attribution.setAppsFlyerConversionData(nil)

    let anyHashableDict: [AnyHashable: Any] = [:]
    attribution.setAppsFlyerConversionData(anyHashableDict)

    let optionalAnyHashableDict: [AnyHashable: Any]? = [:]
    attribution.setAppsFlyerConversionData(optionalAnyHashableDict)

    let stringAnyDict: [String: Any] = [:]
    attribution.setAppsFlyerConversionData(stringAnyDict)

    let stringStringDict: [String: String] = [:]
    attribution.setAppsFlyerConversionData(stringStringDict as [AnyHashable: Any])

    let stringOptionalStringDict: [String: String?] = [:]
    attribution.setAppsFlyerConversionData(stringOptionalStringDict.mapValues { $0 as Any } as [AnyHashable: Any])

    let stringIntDict: [String: Int] = [:]
    attribution.setAppsFlyerConversionData(stringIntDict as [AnyHashable: Any])

    let stringOptionalIntDict: [String: Int?] = [:]
    attribution.setAppsFlyerConversionData(stringOptionalIntDict.mapValues { $0 as Any } as [AnyHashable: Any])

    let nsDictionary: NSDictionary = [:]
    attribution.setAppsFlyerConversionData(nsDictionary as? [AnyHashable: Any])
}
