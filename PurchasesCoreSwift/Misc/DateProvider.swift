//
//  DateProvider.swift
//  PurchasesCoreSwift
//
//  Created by Josh Holtz on 6/28/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

@objc(RCDateProvider) open class DateProvider: NSObject {
    @objc open func now() -> Date {
        return Date()
    }
}
