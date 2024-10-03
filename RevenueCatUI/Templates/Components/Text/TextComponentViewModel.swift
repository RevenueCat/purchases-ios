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
    public func text(for state: ComponentViewState) -> String {
        switch state {
        case .normal: return viewModel.text
        case .selected: return selectedViewModel?.text ?? viewModel.text
        }
    }

    public func fontFamily(for state: ComponentViewState) -> String? {
        switch state {
        case .normal: return viewModel.fontFamily
        case .selected: return selectedViewModel?.fontFamily ?? viewModel.fontFamily
        }
    }

    public func fontWeight(for state: ComponentViewState) -> Font.Weight {
        switch state {
        case .normal: return viewModel.fontWeight
        case .selected: return selectedViewModel?.fontWeight ?? viewModel.fontWeight
        }
    }

    public func color(for state: ComponentViewState) -> Color {
        switch state {
        case .normal: return viewModel.color
        case .selected: return selectedViewModel?.color ?? viewModel.color
        }
    }

    public func textStyle(for state: ComponentViewState) -> Font {
        switch state {
        case .normal: return viewModel.textStyle
        case .selected: return selectedViewModel?.textStyle ?? viewModel.textStyle
        }
    }

    public func horizontalAlignment(for state: ComponentViewState) -> TextAlignment {
        switch state {
        case .normal: return viewModel.horizontalAlignment
        case .selected: return selectedViewModel?.horizontalAlignment ?? viewModel.horizontalAlignment
        }
    }

    public func backgroundColor(for state: ComponentViewState) -> Color {
        switch state {
        case .normal: return viewModel.backgroundColor
        case .selected: return selectedViewModel?.backgroundColor ?? viewModel.backgroundColor
        }
    }

    public func padding(for state: ComponentViewState) -> EdgeInsets {
        switch state {
        case .normal: return viewModel.padding
        case .selected: return selectedViewModel?.padding ?? viewModel.padding
        }
    }

    public func margin(for state: ComponentViewState) -> EdgeInsets {
        switch state {
        case .normal: return viewModel.margin
        case .selected: return selectedViewModel?.margin ?? viewModel.margin
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension TextComponentViewModel {

    public class StatelessTextComponentViewModel {

        private let component: PaywallComponent.TextComponent

        let text: String

        init(localizedStrings: PaywallComponent.LocalizationDictionary, component: PaywallComponent.TextComponent) throws {
            self.component = component
            self.text = try localizedStrings.string(key: component.text)
        }

        public var fontFamily: String? {
            component.fontFamily
        }

        public var fontWeight: Font.Weight {
            component.fontWeight.fontWeight
        }

        public var color: Color {
            component.color.toDyanmicColor()
        }

        public var textStyle: Font {
            component.textStyle.font
        }

        public var horizontalAlignment: TextAlignment {
            component.horizontalAlignment.textAlignment
        }

        public var backgroundColor: Color {
            component.backgroundColor?.toDyanmicColor() ?? Color.clear
        }

        public var padding: EdgeInsets {
            component.padding.edgeInsets
        }

        var margin: EdgeInsets {
            component.margin.edgeInsets
        }

    }

}

#endif
