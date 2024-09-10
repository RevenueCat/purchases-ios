//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ImageComponentView.swift
//
//  Created by Josh Holtz on 6/11/24.
// swiftlint:disable missing_docs

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public class ImageComponentViewModel {

    private let component: PaywallComponent.ImageComponent

    init(component: PaywallComponent.ImageComponent) {
        self.component = component
    }

    private func currentComponent(for selectionState: SelectionState) -> PaywallComponent.ImageComponent {
        switch selectionState {
        case .selected:
            return component.selectedComponent ?? component
        case .unselected:
            return component
        }
    }

    func url(for selectionState: SelectionState) -> URL {
        currentComponent(for: selectionState).url
    }

    func cornerRadius(for selectionState: SelectionState) -> Double {
        currentComponent(for: selectionState).cornerRadius
    }

    func gradientColors(for selectionState: SelectionState) -> [Color] {
        currentComponent(for: selectionState).gradientColors.compactMap { $0.toColor(fallback: Color.clear) }
    }

    func contentMode(for selectionState: SelectionState) -> ContentMode {
        currentComponent(for: selectionState).fitMode.contentMode
    }

    func maxHeight(for selectionState: SelectionState) -> CGFloat? {
        currentComponent(for: selectionState).maxHeight
    }

}

#endif
