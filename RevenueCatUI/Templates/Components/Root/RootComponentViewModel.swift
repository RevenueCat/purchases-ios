//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RootComponentViewModel.swift
//
//  Created by Jay Shortway on 24/10/2024.

import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class RootComponentViewModel {

    private let component: PaywallComponent.RootComponent
    private let stackViewModel: StackComponentViewModel
    private let stickyFooterViewModel: StickyFooterComponentViewModel?

    init(
        component: PaywallComponent.RootComponent,
        stackViewModel: StackComponentViewModel,
        stickyFooterViewModel: StickyFooterComponentViewModel?
    ) {
        self.component = component
        self.stackViewModel = stackViewModel
        self.stickyFooterViewModel = stickyFooterViewModel
    }

}

#endif
