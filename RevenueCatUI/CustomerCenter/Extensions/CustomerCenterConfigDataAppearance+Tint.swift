//
//  Untitled.swift
//  RevenueCatUI
//
//  Created by Facundo Menzella on 22/10/25.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CustomerCenterConfigData.Appearance {

    @available(iOS 15.0, *)
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    func tintColor(colorScheme: ColorScheme) -> Color? {
        Color.from(colorInformation: accentColor, for: colorScheme)
    }
}

#endif
