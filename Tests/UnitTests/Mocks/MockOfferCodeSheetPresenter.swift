//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MockOfferCodeSheetPresenter.swift
//
//  Created by Will Taylor on 10/18/24.

import Foundation

@testable import RevenueCat
import StoreKit

final class MockOfferCodeRedemptionSheetPresenter: OfferCodeRedemptionSheetPresenterType {

    #if (os(iOS) || VISION_OS) && !targetEnvironment(macCatalyst)
    func presentCodeRedemptionSheet(
        windowScene: UIWindowScene,
        storeKitVersion: StoreKitVersion
    ) async throws {}
    #endif

}
