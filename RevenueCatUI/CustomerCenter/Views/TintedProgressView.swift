//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TintedProgressView.swift
//
//  Created by Cesar de la Vega on 19/7/24.

import Foundation
import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct TintedProgressView: View {

    @Environment(\.appearance) private var appearance: CustomerCenterConfigData.Appearance
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ProgressView()
            .controlSize(.regular)
            .tint(colorScheme == .light ? Color.black : Color.white)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct TintedProgressView_Previews: PreviewProvider {

    static var previews: some View {
        TintedProgressView()
            .environment(\.appearance, CustomerCenterConfigData.Appearance(
                accentColor: .init(light: "#ffffff", dark: "#000000"),
                textColor: .init(light: "#000000", dark: "#ffffff"),
                backgroundColor: .init(light: "#000000", dark: "#ffffff"),
                buttonTextColor: .init(light: "#000000", dark: "#ffffff"),
                buttonBackgroundColor: .init(light: "#000000", dark: "#ffffff")
            ))
    }

}

#endif
