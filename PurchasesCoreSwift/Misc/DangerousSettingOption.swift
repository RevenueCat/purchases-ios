//
//  DangerousSettingOption.swift
//  PurchasesCoreSwift
//
//  Created by Cesar de la Vega on 1/25/22.
//  Copyright © 2022 Purchases. All rights reserved.
//

/**
 Only use a Dangerous Setting if suggested by RevenueCat support team.
 */
@objc(RCDangerousSettingOption) enum DangerousSettingOption: Int {

    /**
     Disable
     */
    case off = 0,
         /**
          Enable
          */
         // swiftlint:disable:next identifier_name
         on

}
