//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AppIconDetailProvider.swift
//
//  Created by Jacob Zivan Rakidzich on 12/14/25.

import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class AppIconDetailProvider: ObservableObject {

    let image: Image
    @Published var foundColors: [Color]

    init() {
        image = AppStyleExtractor.getAppIcon()
        let appIconCGImage: CGImage? = AppStyleExtractor.getPlatformAppIconCGImage()
        foundColors = []

        if let appIconCGImage {
            AppStyleExtractor.getProminentColorsFromAppIcon(image: appIconCGImage) {
                self.foundColors = $0
            }
        }
    }

    #if DEBUG
    // For emerge snapshot tests to render correctly, we need scan the image on the main thread
    // so there is no delay between initial render and the found colors being applied to the view
    init(
        image: Image,
        foundColors: [Color]
    ) {
        self.image = image
        self.foundColors = foundColors
    }
    #endif
}
