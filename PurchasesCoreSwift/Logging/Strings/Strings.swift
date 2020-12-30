//
// Created by Andrés Boedo on 9/14/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCStrings) public class Strings: NSObject {
    @objc public static let attribution = AttributionStrings()
    @objc public static let configure = ConfigureStrings()
    @objc public static let identity = IdentityStrings()
    @objc public static let network = NetworkStrings()
    @objc public static let offering = OfferingStrings()
    @objc public static let purchase = PurchaseStrings()
    @objc public static let purchaserInfo = PurchaserInfoStrings()
    @objc public static let receipt = ReceiptStrings()
    @objc public static let restore = RestoreStrings()
}
