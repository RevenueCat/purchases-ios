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

    // swiftlint:disable:next identifier_name
    var rc_languageCode: String? {
        #if swift(>=5.9)
        // `Locale.languageCode` is deprecated
        if #available(macOS 13, iOS 16, tvOS 16, watchOS 9, visionOS 1.0, *) {
            return self.language.languageCode?.identifier
        } else {
            return self.languageCode
        }
        #else
        return self.languageCode
        #endif
    }

    /// - Returns: the same locale as `self` but removing its region.
    var removingRegion: Self? {
        return self.rc_languageCode.map(Locale.init(identifier:))
    }

}
