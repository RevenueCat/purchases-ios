//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StoreProduct+Extensions.swift
//
//  Created by Cesar de la Vega on 25/9/24.

import Foundation
import RevenueCat

extension StoreProduct {

    func localizedPricePerPeriod(_ locale: Locale) -> String {
        guard let period = self.subscriptionPeriod else {
            return self.localizedPriceString
        }

        let unit = Localization.abbreviatedUnitLocalizedString(for: period, locale: locale)
        return "\(self.localizedPriceString)/\(unit)"
    }

}
