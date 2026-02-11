//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallLoadingState.swift
//
//  Created by Facundo Menzella on 2/10/26.
//

import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@MainActor
final class PaywallLoadingState: ObservableObject {

    @Published private(set) var introOfferEligibility: Bool = true
    @Published private(set) var promoOfferEligibility: Bool = true

    // MARK: - Computed Properties

    var isLoadingOfferEligibility: Bool {
        introOfferEligibility || promoOfferEligibility
    }

    var isFullyLoaded: Bool {
        !introOfferEligibility && !promoOfferEligibility
    }

    // MARK: - State Updates

    func setIntroOfferEligibilityLoaded() {
        introOfferEligibility = false
    }

    func setPromoOfferEligibilityLoaded() {
        promoOfferEligibility = false
    }

}

#endif
