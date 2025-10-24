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
class TabControlToggleComponentViewModel {

    let component: PaywallComponent.TabControlToggleComponent
    let uiConfigProvider: UIConfigProvider
    let colorScheme: ColorScheme

    init(
        component: PaywallComponent.TabControlToggleComponent,
        uiConfigProvider: UIConfigProvider,
        colorScheme: ColorScheme
    ) throws {
        self.component = component
        self.uiConfigProvider = uiConfigProvider
        self.colorScheme = colorScheme
    }

    var thumbColorOn: Color {
        return self.component.thumbColorOn
            .asDisplayable(uiConfigProvider: uiConfigProvider)
            .toDynamicColor(with: colorScheme)
    }

    var thumbColorOff: Color {
        return self.component.thumbColorOff
            .asDisplayable(uiConfigProvider: uiConfigProvider)
            .toDynamicColor(with: colorScheme)
    }

    var trackColorOn: Color {
        return self.component.trackColorOn
            .asDisplayable(uiConfigProvider: uiConfigProvider)
            .toDynamicColor(with: colorScheme)
    }

    var trackColorOff: Color {
        return self.component.trackColorOff
            .asDisplayable(uiConfigProvider: uiConfigProvider)
            .toDynamicColor(with: colorScheme)
    }

}

#endif
