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
//  Created by Nacho Soto on 6/21/23.

import Foundation

extension Locale {

    // swiftlint:disable:next identifier_name
    var rc_currencyCode: String? {
        #if swift(>=5.9)
        // `Locale.currencyCode` is deprecated
        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, visionOS 1.0, *) {
            return self.currency?.identifier
        } else {
            return self.currencyCode
        }
        #else
        return self.currencyCode
        #endif
    }

}
