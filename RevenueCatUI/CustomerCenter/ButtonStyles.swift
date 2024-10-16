//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ButtonStyles.swift
//
//
//  Created by Cesar de la Vega on 28/5/24.
//

import Foundation
import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ProminentButtonStyle: PrimitiveButtonStyle {

    @Environment(\.appearance) private var appearance: CustomerCenterConfigData.Appearance
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: PrimitiveButtonStyleConfiguration) -> some View {
        let background = Color.from(colorInformation: appearance.buttonBackgroundColor, for: colorScheme)
        let textColor = Color.from(colorInformation: appearance.buttonTextColor, for: colorScheme)

        Button(action: { configuration.trigger() }, label: {
            configuration.label.frame(maxWidth: .infinity)
        })
        .font(.body.weight(.medium))
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .buttonBorderShape(.roundedRectangle(radius: 16))
        .applyIf(background != nil, apply: { $0.tint(background) })
        .applyIf(textColor != nil, apply: { $0.foregroundColor(textColor) })
    }

}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct DismissCircleButton: View {

    @Environment(\.localization) private var localization
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            self.dismiss()
        } label: {
            Circle()
                .fill(Color(uiColor: .secondarySystemFill))
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.secondary)
                        .imageScale(.medium)
                )
            }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(localization.commonLocalizedString(for: .dismiss)))
    }

}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ButtonStyles_Previews: PreviewProvider {

    static var previews: some View {
        VStack(spacing: 16.0) {
            Button("Didn't receive purchase") {}
                .buttonStyle(ProminentButtonStyle())

            DismissCircleButton()
        }.padding()
            .environment(\.appearance, CustomerCenterConfigTestData.standardAppearance)
            .environment(\.localization, CustomerCenterConfigTestData.customerCenterData.localization)
    }

}

#endif
