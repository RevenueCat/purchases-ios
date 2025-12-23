//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CustomerCenterConfigDataSupport+Button.swift
//
//  Created by Facundo Menzella on 2/4/25.

import Foundation
@_spi(Internal) import RevenueCat

#if os(iOS)

extension CustomerCenterConfigData.Support {

    @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    func supportURL(localization: CustomerCenterConfigData.Localization,
                    purchasesProvider: CustomerCenterPurchasesType) -> URL? {
        let subject = localization[.defaultSubject]
        let body = calculateBody(localization, purchasesProvider: purchasesProvider)

        return URLUtilities.createMailURLIfPossible(
            email: email,
            subject: subject,
            body: body)
    }
}

#endif
