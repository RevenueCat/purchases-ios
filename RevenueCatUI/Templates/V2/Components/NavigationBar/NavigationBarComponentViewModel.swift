//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  NavigationBarComponentViewModel.swift
//
//  Created by Josh Holtz on 2/7/25.

import RevenueCat
import SwiftUI

#if !os(macOS) && !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class NavigationBarComponentViewModel {

    let component: PaywallComponent.NavigationBarComponent

    let leadingStackViewModel: StackComponentViewModel?
    let trailingStackViewModel: StackComponentViewModel?

    init(
        component: PaywallComponent.NavigationBarComponent,
        leadingStackViewModel: StackComponentViewModel?,
        trailingStackViewModel: StackComponentViewModel?
    ) {
        self.component = component
        self.leadingStackViewModel = leadingStackViewModel
        self.trailingStackViewModel = trailingStackViewModel
    }

}

#endif
