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
// swiftlint:disable missing_docs

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public class TextComponentViewModel {

    let localizedStrings: PaywallComponent.LocalizationDictionary
    let text: String

    private let component: PaywallComponent.TextComponent

    init(localizedStrings: PaywallComponent.LocalizationDictionary, component: PaywallComponent.TextComponent) throws {
        self.localizedStrings = localizedStrings
        self.component = component
        self.text = try localizedStrings.string(key: component.textLid)
    }

    private func currentComponent(for selectionState: SelectionState) -> PaywallComponent.TextComponent {
        switch selectionState {
        case .selected:
            return component.selectedComponent ?? component
        case .unselected:
            return component
        }
    }

    func fontFamily(for selectionState: SelectionState) -> String {
        currentComponent(for: selectionState).fontFamily
    }

    func fontWeight(for selectionState: SelectionState) -> Font.Weight {
        currentComponent(for: selectionState).fontWeight.fontWeight
    }

    func color(for selectionState: SelectionState) -> Color {
        currentComponent(for: selectionState).color.toDyanmicColor()
    }

    func textStyle(for selectionState: SelectionState) -> Font {
        currentComponent(for: selectionState).textStyle.font
    }

    func horizontalAlignment(for selectionState: SelectionState) -> TextAlignment {
        currentComponent(for: selectionState).horizontalAlignment.textAlignment
    }

    func backgroundColor(for selectionState: SelectionState) -> Color {
        currentComponent(for: selectionState).backgroundColor?.toDyanmicColor() ?? Color.clear
    }

    func padding(for selectionState: SelectionState) -> EdgeInsets {
        currentComponent(for: selectionState).padding.edgeInsets
    }

}
#endif
