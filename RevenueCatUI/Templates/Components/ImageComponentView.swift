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
struct ImageComponentView: View {

    let locale: Locale
    let component: PaywallComponent.ImageComponent

    var cornerRadius: CGFloat {
        component.cornerRadius
    }

    var gradientColors: [Color] {
        component.gradientColors.compactMap { try? $0.toColor() }
    }

    var contentMode: ContentMode {
        component.fitMode.contentMode
    }

    var body: some View {
        RemoteImage(url: component.url) { image in
            image
                .resizable()
                .aspectRatio(contentMode: self.contentMode)
                .frame(maxHeight: component.maxHeight)
                .overlay(
                    LinearGradient(
                        gradient: Gradient(colors: gradientColors),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                .cornerRadius(cornerRadius)
        }
//        .clipped()
    }

}

private extension PaywallComponent.ImageComponent.FitMode {
    var contentMode: ContentMode {
        switch self {
        case .fit:
            ContentMode.fit
        case .crop:
            ContentMode.fill
        }
    }
}

#endif
