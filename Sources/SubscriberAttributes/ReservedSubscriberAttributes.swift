//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ReservedSubscriberAttributes.swift
//
//  Created by César de la Vega on 6/17/21.
//

import Foundation

// swiftlint:disable identifier_name
enum ReservedSubscriberAttribute: String {

    var key: String { rawValue }

    case email = "$email"
    case phoneNumber = "$phoneNumber"
    case displayName = "$displayName"
    case pushToken = "$apnsTokens"

    case idfa = "$idfa"
    case idfv = "$idfv"
    case gpsAdId = "$gpsAdId"
    case consentStatus = "$attConsentStatus"

    case ip = "$ip"

    case adjustID = "$adjustId"
    case appsFlyerID = "$appsflyerId"
    case fBAnonID = "$fbAnonId"
    case mpParticleID = "$mparticleId"
    case oneSignalID = "$onesignalId"
    case airshipChannelID = "$airshipChannelId"
    case cleverTapID = "$clevertapId"
    case mixpanelDistinctID = "$mixpanelDistinctId"
    case firebaseAppInstanceID = "$firebaseAppInstanceId"

    case mediaSource = "$mediaSource"
    case campaign = "$campaign"
    case adGroup = "$adGroup"
    case ad = "$ad"
    case keyword = "$keyword"
    case creative = "$creative"

}
