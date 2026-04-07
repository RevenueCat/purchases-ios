//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HeaderComponentViewModel.swift
//
//  Created by Facundo Menzella on 02/04/2026.

@_spi(Internal) import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class HeaderComponentViewModel {

    let component: PaywallComponent.HeaderComponent
    let stackViewModel: StackComponentViewModel

    init(
        component: PaywallComponent.HeaderComponent,
        stackViewModel: StackComponentViewModel
    ) {
        self.component = component
        self.stackViewModel = stackViewModel
    }

}

#endif
