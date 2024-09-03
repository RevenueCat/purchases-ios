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

import Combine
import Foundation
import RevenueCat
import SwiftUI

#if PAYWALL_COMPONENTS

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
public class ImageComponentViewModel: ObservableObject {

    @Published private(set) var component: PaywallComponent.ImageComponent

    init(component: PaywallComponent.ImageComponent) {
        self.component = component
    }

    public var url: URL {
        component.url
    }
    public var cornerRadius: Double {
        component.cornerRadius
    }
    public var gradientColors: [Color] {
        component.gradientColors.compactMap { $0.toColor(fallback: Color.clear) }
    }
    public var contentMode: ContentMode {
        component.fitMode.contentMode
    }
    public var maxHeight: CGFloat? {
        component.maxHeight
    }

}

#endif
