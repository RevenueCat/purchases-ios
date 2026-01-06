//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TabsComponentViewModel.swift
//
//  Created by Josh Holtz on 1/9/25.

import RevenueCat
import SwiftUI

#if !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TabControlComponentViewModel {

    let component: PaywallComponent.TabControlComponent
    let uiConfigProvider: UIConfigProvider

    init(
        component: PaywallComponent.TabControlComponent,
        uiConfigProvider: UIConfigProvider
    ) throws {
        self.component = component
        self.uiConfigProvider = uiConfigProvider
    }

}

#endif
