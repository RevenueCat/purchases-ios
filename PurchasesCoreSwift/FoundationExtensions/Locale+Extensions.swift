//
//  Locale+Extensions.swift
//  PurchasesCoreSwift
//
//  Created by Josh Holtz on 6/28/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

extension Locale {
    func rc_currencyCode() -> String? {
        if #available(iOS 10.0, macOS 10.12, tvOS 10.0, macCatalyst 13.0, *) {
            return self.currencyCode
        } else {
            return (self as NSLocale).object(forKey: NSLocale.Key.currencyCode) as? String
        }
    }
}
