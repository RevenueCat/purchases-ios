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
enum SpecialSubscriberAttribute {

    case email
    case phoneNumber
    case displayName
    case pushToken

    case idfa
    case idfv
    case gpsAdId

    case ip

    case adjustID
    case appsFlyerID
    case fBAnonID
    case mpParticleID
    case oneSignalID
    case airshipChannelID

    case mediaSource
    case campaign
    case adGroup
    case ad
    case keyword
    case creative

    var key: String { description }

}

extension SpecialSubscriberAttribute: CustomStringConvertible {

    var description: String {

        switch self {
        case .email: return "$email"
        case .phoneNumber: return "$phoneNumber"
        case .displayName: return "$displayName"
        case .pushToken: return "$apnsTokens"
        case .idfa: return "$idfa"
        case .idfv: return "$idfv"
        case .gpsAdId: return "$gpsAdId"
        case .ip: return "$ip"
        case .adjustID: return "$adjustId"
        case .appsFlyerID: return "$appsflyerId"
        case .fBAnonID: return "$fbAnonId"
        case .mpParticleID: return "$mparticleId"
        case .oneSignalID: return "$onesignalId"
        case .mediaSource: return "$mediaSource"
        case .campaign: return "$campaign"
        case .adGroup: return "$adGroup"
        case .ad: return "$ad"
        case .keyword: return "$keyword"
        case .creative: return "$creative"
        case .airshipChannelID: return "$airshipChannelID"

        }
    }

}
