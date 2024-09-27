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

    private let localizedStrings: PaywallComponent.LocalizationDictionary

    private let component: StatelessImageComponentViewModel
    private let selectedComponent: StatelessImageComponentViewModel?

    init(localizedStrings: PaywallComponent.LocalizationDictionary, component: PaywallComponent.ImageComponent) throws {
        self.localizedStrings = localizedStrings

        self.component = try StatelessImageComponentViewModel(
            localizedStrings: localizedStrings,
            component: component
        )
        self.selectedComponent = try component.selectedComponent.flatMap {
            try StatelessImageComponentViewModel(
                localizedStrings: localizedStrings,
                component: $0
            )
        }
    }

    private func currentComponent(for selectionState: SelectionState) -> StatelessImageComponentViewModel {
        switch selectionState {
        case .selected:
            return selectedComponent ?? component
        case .unselected:
            return component
        }
    }

    func url(for selectionState: SelectionState) -> URL {
        currentComponent(for: selectionState).url
    }

    func cornerRadiuses(for selectionState: SelectionState) -> PaywallComponent.CornerRadiuses {
        currentComponent(for: selectionState).cornerRadiuses
    }

    func gradientColors(for selectionState: SelectionState) -> [Color] {
        currentComponent(for: selectionState).gradientColors
    }

    func contentMode(for selectionState: SelectionState) -> ContentMode {
        currentComponent(for: selectionState).contentMode
    }

    func maxHeight(for selectionState: SelectionState) -> CGFloat? {
        currentComponent(for: selectionState).maxHeight
    }

}

fileprivate struct StatelessImageComponentViewModel {

    private let localizedStrings: PaywallComponent.LocalizationDictionary
    private let component: PaywallComponent.ImageComponent

    private let imageInfo: PaywallComponent.ThemeImageUrls

    init(localizedStrings: PaywallComponent.LocalizationDictionary, component: PaywallComponent.ImageComponent) throws {
        self.localizedStrings = localizedStrings
        self.component = component

        if let overrideSourceLid = component.overrideSourceLid {
            self.imageInfo = try localizedStrings.image(key: overrideSourceLid)
        } else {
            self.imageInfo = component.source
        }
    }

    var url: URL {
        return imageInfo.light.heic
    }

    var cornerRadiuses: PaywallComponent.CornerRadiuses {
        return component.cornerRadiuses
    }

    var gradientColors: [Color] {
        return component.gradientColors?.compactMap { $0.toColor(fallback: Color.clear) } ?? []
    }

    var contentMode: ContentMode {
        return component.fitMode.contentMode
    }

    var maxHeight: CGFloat? {
        return component.maxHeight
    }

}

#endif
