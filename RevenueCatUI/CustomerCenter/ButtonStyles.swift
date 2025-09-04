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
@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ProminentButtonStyle: PrimitiveButtonStyle {

    @Environment(\.appearance) private var appearance: CustomerCenterConfigData.Appearance
    @Environment(\.colorScheme) private var colorScheme
    private var needsLegacyBorderShape: Bool {
        #if swift(>=6.2)
        if #available(iOS 26.0, *) { false } else { true }
        #else
        true
        #endif
    }

    func makeBody(configuration: PrimitiveButtonStyleConfiguration) -> some View {
        let background = Color.from(colorInformation: appearance.buttonBackgroundColor, for: colorScheme)
        let textColor = Color.from(colorInformation: appearance.buttonTextColor, for: colorScheme)

        Button(action: { configuration.trigger() }, label: {
            configuration.label.frame(maxWidth: .infinity)
        })
        .font(.body.weight(.medium))
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .applyIf(background != nil, apply: { $0.tint(background) })
        .applyIf(textColor != nil, apply: { $0.foregroundColor(textColor) })
        .applyIf(needsLegacyBorderShape, apply: { $0 .buttonBorderShape(.roundedRectangle(radius: 16)) })
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CustomerCenterButtonStyle: ButtonStyle {
    let normalColor: Color
    let pressedColor: Color

    func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(configuration.isPressed ? pressedColor : normalColor)
            .cornerRadius(10)
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension ButtonStyle where Self == CustomerCenterButtonStyle {
    static func customerCenterButtonStyle(for colorScheme: ColorScheme) -> CustomerCenterButtonStyle {
        CustomerCenterButtonStyle(
            normalColor: Color(colorScheme == .light
                               ? UIColor.systemBackground
                               : UIColor.secondarySystemBackground),
            pressedColor: Color(colorScheme == .light
                                ? UIColor.secondarySystemBackground
                                : UIColor.systemBackground)
        )
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct DismissCircleButton: View {

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.localization)
    private var localization

    var customDismiss: (() -> Void)?

    var body: some View {
#if swift(>=6.2)
        if #available(iOS 26.0, *) {
            Button(role: .close) {
                if let customDismiss {
                    customDismiss()
                } else {
                    self.dismiss()
                }
            }
            .accessibilityIdentifier("circled_close_button")
            .accessibilityLabel(Text(localization[.dismiss]))
        } else {
            Button {
                if let customDismiss {
                    customDismiss()
                } else {
                    self.dismiss()
                }
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
            .accessibilityIdentifier("circled_close_button")
            .accessibilityLabel(Text(localization[.dismiss]))
        }
        #else
        Button {
            if let customDismiss {
                customDismiss()
            } else {
                self.dismiss()
            }
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
        .accessibilityIdentifier("circled_close_button")
        .accessibilityLabel(Text(localization[.dismiss]))
        #endif
    }

}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct DismissCircleButtonToolbarModifier: ViewModifier {

    @Environment(\.navigationOptions)
    var navigationOptions

    func body(content: Content) -> some View {
        if navigationOptions.shouldShowCloseButton {
            content
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        DismissCircleButton(customDismiss: navigationOptions.onCloseHandler)
                    }
                }
        } else {
            content
        }

    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension View {
    /// Adds a toolbar with a dismiss button if `navigationOptions.shouldShowCloseButton` is true.
    func dismissCircleButtonToolbarIfNeeded() -> some View {
        modifier(DismissCircleButtonToolbarModifier())
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
            .environment(\.appearance, CustomerCenterConfigData.standardAppearance)
            .environment(\.localization, CustomerCenterConfigData.default.localization)
    }

}

#endif
