//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CarouselComponentViewModel.swift
//
//  Created by Josh Holtz on 1/27/25.

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class CarouselComponentViewModel {

    private let localizationProvider: LocalizationProvider
    let uiConfigProvider: UIConfigProvider
    let component: PaywallComponent.CarouselComponent
    let pageStackViewModels: [StackComponentViewModel]

//    private let presentedOverrides: PresentedOverrides<LocalizedImagePartial>?

    init(
        localizationProvider: LocalizationProvider,
        uiConfigProvider: UIConfigProvider,
        component: PaywallComponent.CarouselComponent,
        pageStackViewModels: [StackComponentViewModel]
    ) throws {
        self.localizationProvider = localizationProvider
        self.uiConfigProvider = uiConfigProvider
        self.component = component
        self.pageStackViewModels = pageStackViewModels

//        self.presentedOverrides = try self.component.overrides?.toPresentedOverrides {
//            try LocalizedImagePartial.create(from: $0, using: localizationProvider.localizedStrings)
//        }
    }

}

#endif
