//
//  Untitled.swift
//  RevenueCatUI
//
//  Created by Facundo Menzella on 22/10/25.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

@_spi(Internal) import RevenueCat
import SwiftUI

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CustomerCenterConfigData.Appearance {

    func tintColor(colorScheme: ColorScheme) -> Color? {
        Color.from(colorInformation: accentColor, for: colorScheme)
    }
}
