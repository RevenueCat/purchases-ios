//
//  SpecialSubscriberAttributes.swift
//  PurchasesCoreSwift
//
//  Created by César de la Vega on 6/17/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

// swiftlint:disable identifier_name
@objc(RCSpecialSubscriberAttributes) public class SpecialSubscriberAttributes: NSObject {
    @objc public static let email = "$email"
    @objc public static let phoneNumber = "$phoneNumber"
    @objc public static let displayName = "$displayName"
    @objc public static let pushToken = "$apnsTokens"

    @objc public static let idfa = "$idfa"
    @objc public static let idfv = "$idfv"
    @objc public static let gpsAdId = "$gpsAdId"

    @objc public static let ip = "$ip"

    @objc public static let adjustID = "$adjustId"
    @objc public static let appsFlyerID = "$appsflyerId"
    @objc public static let fBAnonID = "$fbAnonId"
    @objc public static let mpParticleID = "$mparticleId"
    @objc public static let oneSignalID = "$onesignalId"
    @objc public static let airshipChannelID = "$airshipChannelId"

    @objc public static let mediaSource = "$mediaSource"
    @objc public static let campaign = "$campaign"
    @objc public static let adGroup = "$adGroup"
    @objc public static let ad = "$ad"
    @objc public static let keyword = "$keyword"
    @objc public static let creative = "$creative"
}
