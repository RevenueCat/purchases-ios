//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TextComponentView.swift
//
//  Created by Josh Holtz on 6/11/24.

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class TextComponentViewModel {

    private let viewModel: StatelessTextComponentViewModel
    private let selectedViewModel: StatelessTextComponentViewModel?

    init(localizedStrings: PaywallComponent.LocalizationDictionary, component: PaywallComponent.TextComponent) throws {
        self.viewModel = try StatelessTextComponentViewModel(
            localizedStrings: localizedStrings,
            component: component
        )
        self.selectedViewModel = try component.selectedState.flatMap({ selectedComponent in
            try StatelessTextComponentViewModel(
                localizedStrings: localizedStrings,
                component: selectedComponent
            )
        })
    }

    // Updated functions with renamed enum
    func text(for state: ComponentViewState) -> String {
        switch state {
        case .normal: return viewModel.text
        case .selected: return selectedViewModel?.text ?? viewModel.text
        }
    }

    func fontFamily(for state: ComponentViewState) -> String? {
        switch state {
        case .normal: return viewModel.fontFamily
        case .selected: return selectedViewModel?.fontFamily ?? viewModel.fontFamily
        }
    }

    func fontWeight(for state: ComponentViewState) -> Font.Weight {
        switch state {
        case .normal: return viewModel.fontWeight
        case .selected: return selectedViewModel?.fontWeight ?? viewModel.fontWeight
        }
    }

    func color(for state: ComponentViewState) -> Color {
        switch state {
        case .normal: return viewModel.color
        case .selected: return selectedViewModel?.color ?? viewModel.color
        }
    }

    func textStyle(for state: ComponentViewState) -> Font {
        switch state {
        case .normal: return viewModel.textStyle
        case .selected: return selectedViewModel?.textStyle ?? viewModel.textStyle
        }
    }

    func horizontalAlignment(for state: ComponentViewState) -> TextAlignment {
        switch state {
        case .normal: return viewModel.horizontalAlignment
        case .selected: return selectedViewModel?.horizontalAlignment ?? viewModel.horizontalAlignment
        }
    }

    func backgroundColor(for state: ComponentViewState) -> Color {
        switch state {
        case .normal: return viewModel.backgroundColor
        case .selected: return selectedViewModel?.backgroundColor ?? viewModel.backgroundColor
        }
    }

    func padding(for state: ComponentViewState) -> EdgeInsets {
        switch state {
        case .normal: return viewModel.padding
        case .selected: return selectedViewModel?.padding ?? viewModel.padding
        }
    }

    func margin(for state: ComponentViewState) -> EdgeInsets {
        switch state {
        case .normal: return viewModel.margin
        case .selected: return selectedViewModel?.margin ?? viewModel.margin
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension TextComponentViewModel {

    class StatelessTextComponentViewModel {

        private let component: PaywallComponent.TextComponent

        let text: String

        init(
            localizedStrings: PaywallComponent.LocalizationDictionary,
            component: PaywallComponent.TextComponent
        ) throws {
            self.component = component
            self.text = try localizedStrings.string(key: component.text)
        }

        var fontFamily: String? {
            component.fontFamily
        }

        var fontWeight: Font.Weight {
            component.fontWeight.fontWeight
        }

        var color: Color {
            component.color.toDyanmicColor()
        }

        var textStyle: Font {
            component.textStyle.font
        }

        var horizontalAlignment: TextAlignment {
            component.horizontalAlignment.textAlignment
        }

        var backgroundColor: Color {
            component.backgroundColor?.toDyanmicColor() ?? Color.clear
        }

        var padding: EdgeInsets {
            component.padding.edgeInsets
        }

        var margin: EdgeInsets {
            component.margin.edgeInsets
        }

    }

}

#endif
