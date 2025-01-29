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

#if !os(macOS) && !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TabsComponentViewModel {

    private let component: PaywallComponent.TabsComponent
    let uiConfigProvider: UIConfigProvider

    let controlStackViewModel: StackComponentViewModel
    let tabViewModels: [TabViewModel]

    init(
        component: PaywallComponent.TabsComponent,
        controlStackViewModel: StackComponentViewModel,
        tabViewModels: [TabViewModel],
        uiConfigProvider: UIConfigProvider
    ) throws {
        self.component = component
        self.controlStackViewModel = controlStackViewModel
        self.tabViewModels = tabViewModels
        self.uiConfigProvider = uiConfigProvider
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TabViewModel {

    private let tab: PaywallComponent.TabsComponent.Tab
    let uiConfigProvider: UIConfigProvider
    let stackViewModel: StackComponentViewModel
    let defaultSelectedPackage: Package?
    let packages: [Package]

    init(
        tab: PaywallComponent.TabsComponent.Tab,
        stackViewModel: StackComponentViewModel,
        defaultSelectedPackage: Package?,
        packages: [Package],
        uiConfigProvider: UIConfigProvider
    ) throws {
        self.tab = tab
        self.stackViewModel = stackViewModel
        self.defaultSelectedPackage = defaultSelectedPackage
        self.packages = packages
        self.uiConfigProvider = uiConfigProvider
    }

}

#endif
