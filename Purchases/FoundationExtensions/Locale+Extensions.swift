//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Locale+Extensions.swift
//
//  Created by Josh Holtz on 6/28/21.
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
