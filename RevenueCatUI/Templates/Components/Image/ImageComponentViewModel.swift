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

import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
class ImageComponentViewModel {

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
        self.imageInfo.light.heic
    }

    var shape: ShapeModifier.Shape? {
        guard let shape = self.component.maskShape else {
            return nil
        }

        switch shape {
        case .rectangle(let cornerRadiuses):
            let corners = cornerRadiuses.flatMap { cornerRadiuses in
                ShapeModifier.RaidusInfo(
                    topLeft: cornerRadiuses.topLeading,
                    topRight: cornerRadiuses.topTrailing,
                    bottomLeft: cornerRadiuses.bottomLeading,
                    bottomRight: cornerRadiuses.bottomLeading
                )
            }
            return .rectangle(corners)
        case .pill:
            return .pill
        case .concave:
            return .concave
        case .convex:
            return .convex
        }
    }

    var gradientColors: [Color] {
        component.gradientColors?.compactMap { $0.toColor(fallback: Color.clear) } ?? []
    }

    var contentMode: ContentMode {
        component.fitMode.contentMode
    }

    var maxHeight: CGFloat? {
        component.maxHeight
    }

}

#endif
