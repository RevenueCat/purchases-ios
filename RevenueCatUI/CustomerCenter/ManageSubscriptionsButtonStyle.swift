//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ManageSubscriptionsButtonStyle.swift
//
//
//  Created by Cesar de la Vega on 28/5/24.
//

import Foundation
import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ManageSubscriptionsButtonStyle: ButtonStyle {

    @Environment(\.appearance) private var appearance: CustomerCenterConfigData.Appearance
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .padding()
            .frame(width: 300)
            .background(color(from: appearance))
            .foregroundColor(colorScheme == .dark ? Color.black : Color.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private extension ManageSubscriptionsButtonStyle {

    func color(from appearance: CustomerCenterConfigData.Appearance) -> Color {
        switch appearance.mode {
        case .system:
            return Color.accentColor
        case .custom(accentColor: let accentColor, backgroundColor: _, textColor: _):
            return colorScheme == .dark ? accentColor.dark.underlyingColor : accentColor.light.underlyingColor
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ManageSubscriptionsButtonStyle_Previews: PreviewProvider {

    static var previews: some View {
        Button("Didn't receive purchase") {}
            .buttonStyle(ManageSubscriptionsButtonStyle())
            .environment(\.appearance, CustomerCenterConfigData.Appearance(mode: .system))
    }

}