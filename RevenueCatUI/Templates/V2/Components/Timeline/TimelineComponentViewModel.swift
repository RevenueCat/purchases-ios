//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TimelineComponentViewModel.swift
//
//  Created by Mark Villacampa on 15/1/25.

import Foundation
import RevenueCat

#if !os(macOS) && !os(tvOS) // For Paywalls V2

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TimelineComponentViewModel {

    let component: PaywallComponent.TimelineComponent
    let items: [TimelineItemViewModel]
    let uiConfigProvider: UIConfigProvider
    let id = UUID()

    init(
        component: PaywallComponent.TimelineComponent,
        items: [TimelineItemViewModel],
        uiConfigProvider: UIConfigProvider
    ) throws {
        self.component = component
        self.items = items
        self.uiConfigProvider = uiConfigProvider
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TimelineItemViewModel {
    let id = UUID()
    let component: PaywallComponent.TimelineComponent.Item
    let title: TextComponentViewModel
    let description: TextComponentViewModel?
    let icon: IconComponentViewModel

    init(component: PaywallComponent.TimelineComponent.Item,
         title: TextComponentViewModel,
         description: TextComponentViewModel?,
         icon: IconComponentViewModel) {
        self.component = component
        self.title = title
        self.description = description
        self.icon = icon
    }
}

#endif
