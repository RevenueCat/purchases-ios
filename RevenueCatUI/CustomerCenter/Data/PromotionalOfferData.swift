//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PromotionalOfferData.swift
//
//  Created by Cesar de la Vega on 17/7/24.

#if CUSTOMER_CENTER_ENABLED

import Foundation
import RevenueCat

struct PromotionalOfferData: Identifiable {

    let id = UUID()
    let promotionalOffer: PromotionalOffer
    let product: StoreProduct
    let promoOfferDetails: CustomerCenterConfigData.HelpPath.PromotionalOffer

}

#endif
