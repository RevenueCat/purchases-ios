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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct ImageComponentView: View {

    let locale: Locale
    let component: PaywallComponent.ImageComponent

    @Environment(\.userInterfaceIdiom)
    var userInterfaceIdiom

    private var headerAspectRatio: CGFloat {
        switch self.userInterfaceIdiom {
        case .pad: return 3
        default: return 2
        }
    }

    var body: some View {
        RemoteImage(url: component.url,
                    aspectRatio: self.headerAspectRatio,
                    maxWidth: .infinity)
        .clipped()
    }

}
