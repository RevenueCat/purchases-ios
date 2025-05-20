//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocalizationDictionaryExtensions.swift
//
//  Created by Josh Holtz on 5/14/25.

import Foundation
@_spi(Internal) import RevenueCat

extension PaywallComponent.LocalizationDictionary {

    func urlFromLid(_ urlLid: String) throws -> URL {
        do {
            return try url(key: urlLid)
        } catch {
            Logger.error(Strings.paywall_invalid_url(urlLid))
            throw error
        }
    }

}
