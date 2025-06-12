//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  View+Appearance.swift
//
//  Created by Cesar de la Vega on 30/7/24.

import Foundation
@_spi(Internal) import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension Color {
    static func from(colorInformation: CustomerCenterConfigData.Appearance.ColorInformation,
                     for colorScheme: ColorScheme) -> Color? {
        return colorScheme == .dark ? colorInformation.dark?.underlyingColor : colorInformation.light?.underlyingColor
    }
}
