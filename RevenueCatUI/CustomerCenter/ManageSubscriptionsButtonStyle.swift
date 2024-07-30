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
        let background = color(from: appearance.buttonBackgroundColor)
        let textColor = color(from: appearance.buttonTextColor)
        configuration.label
            .padding()
            .frame(width: 300)
            .applyIf(background != nil, apply: { $0.background(background) })
            .applyIf(textColor != nil, apply: { $0.foregroundColor(textColor) })
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

    func color(from colorInformation: CustomerCenterConfigData.Appearance.ColorInformation) -> Color? {
        return colorScheme == .dark ? colorInformation.dark?.underlyingColor : colorInformation.light?.underlyingColor
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
            .environment(\.appearance, CustomerCenterConfigData.Appearance(
                accentColor: .init(light: "#ffffff", dark: "#000000"),
                textColor: .init(light: "#000000", dark: "#ffffff"),
                backgroundColor: .init(light: "#000000", dark: "#ffffff"),
                buttonTextColor: .init(light: "#ffffff", dark: "#000000"),
                buttonBackgroundColor: .init(light: "#000000", dark: "#ffffff")
            ))
    }

}
