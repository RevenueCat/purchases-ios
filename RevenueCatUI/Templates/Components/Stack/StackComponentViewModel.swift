//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  StackComponentView.swift
//
//  Created by James Borthwick on 2024-08-20.
// swiftlint:disable missing_docs

import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public class StackComponentViewModel {

    let locale: Locale
    private let unselectedViewModels: [PaywallComponentViewModel]
    private let selectedViewModels: [PaywallComponentViewModel]?
    private let component: PaywallComponent.StackComponent

    init(locale: Locale,
         component: PaywallComponent.StackComponent,
         localizedStrings: PaywallComponent.LocalizationDictionary,
         offering: Offering
    ) throws {
        self.locale = locale
        self.component = component
        self.unselectedViewModels = try component.components.map {
            try $0.toViewModel(offering: offering, locale: locale, localizedStrings: localizedStrings)
        }
        self.selectedViewModels = try component.selectedComponent?.components.map {
            try $0.toViewModel(offering: offering, locale: locale, localizedStrings: localizedStrings)
        }
    }

    private func currentComponent(for selectionState: SelectionState) -> PaywallComponent.StackComponent {
        switch selectionState {
        case .selected:
            return component.selectedComponent ?? component
        case .unselected:
            return component
        }
    }

    func viewModels(for selectionState: SelectionState) -> [PaywallComponentViewModel] {
        switch selectionState {
        case .selected:
            return selectedViewModels ?? unselectedViewModels
        case .unselected:
            return unselectedViewModels
        }
    }

    func dimension(for selectionState: SelectionState) -> PaywallComponent.StackComponent.Dimension {
        currentComponent(for: selectionState).dimension
    }

    var components: [PaywallComponent] {
        component.components
    }

    func spacing(for selectionState: SelectionState) -> CGFloat? {
        currentComponent(for: selectionState).spacing
    }

    func backgroundColor(for selectionState: SelectionState) -> Color {
        currentComponent(for: selectionState).backgroundColor?.toDyanmicColor() ?? Color.clear
    }

    func padding(for selectionState: SelectionState) -> EdgeInsets {
        currentComponent(for: selectionState).padding.edgeInsets
    }

}

#endif
