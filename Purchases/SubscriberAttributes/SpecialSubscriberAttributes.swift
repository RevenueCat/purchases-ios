//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SpecialSubscriberAttributes.swift
//
//  Created by César de la Vega on 6/17/21.
//

import Foundation

// swiftlint:disable identifier_name
struct SpecialSubscriberAttributes {

    static let email = "$email"
    static let phoneNumber = "$phoneNumber"
    static let displayName = "$displayName"
    static let pushToken = "$apnsTokens"

    static let idfa = "$idfa"
    static let idfv = "$idfv"
    static let gpsAdId = "$gpsAdId"

    static let ip = "$ip"

    static let adjustID = "$adjustId"
    static let appsFlyerID = "$appsflyerId"
    static let fBAnonID = "$fbAnonId"
    static let mpParticleID = "$mparticleId"
    static let oneSignalID = "$onesignalId"

    static let mediaSource = "$mediaSource"
    static let campaign = "$campaign"
    static let adGroup = "$adGroup"
    static let ad = "$ad"
    static let keyword = "$keyword"
    static let creative = "$creative"

}
