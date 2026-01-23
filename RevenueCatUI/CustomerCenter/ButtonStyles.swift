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
        #if compiler(>=6.2)
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
            .cornerRadius(CustomerCenterStylingUtilities.cornerRadius)
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
/// A circular close button used in the Customer Center toolbar.
///
/// Important: This view intentionally does not read `@Environment(\.dismiss)`
/// to avoid dismissal issues on iOS 15. The dismiss action must be provided
/// via the `onDismiss` parameter, typically sourced from
/// `CustomerCenterNavigationOptions.onCloseHandler`, which is injected by
/// `CustomerCenterView`.
struct DismissCircleButton: View {

    @Environment(\.localization)
    private var localization

    let onDismiss: () -> Void

    var body: some View {
#if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            Button(role: .close) {
                onDismiss()
            }
            .accessibilityIdentifier("circled_close_button")
            .accessibilityLabel(Text(localization[.dismiss]))
        } else {
            Button {
                onDismiss()
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
            onDismiss()
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
struct DismissCircleToolbar: ViewModifier {
    @Environment(\.dismiss)
    private var dismiss

    let options: CustomerCenterNavigationOptions

    private var customDismiss: (() -> Void)?

    init(options: CustomerCenterNavigationOptions, customDismiss: (() -> Void)?) {
        self.options = options
        self.customDismiss = customDismiss
    }

    func body(content: Content) -> some View {
        #if compiler(>=5.9)
        if options.shouldShowCloseButton {
            let onClose = customDismiss ?? options.onCloseHandler ?? { dismiss() }
            content
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        DismissCircleButton(onDismiss: onClose)
                    }
                }
        } else {
            content
        }
        #else
        content
        #endif
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension View {
    /// Adds a toolbar with a dismiss button if `options.shouldShowCloseButton` is true,
    /// using explicit options.
    func dismissCircleButtonToolbarIfNeeded(navigationOptions: CustomerCenterNavigationOptions) -> some View {
        modifier(DismissCircleToolbar(options: navigationOptions, customDismiss: nil))
    }

    /// Adds a toolbar with a dismiss button if `navigationOptions.shouldShowCloseButton` is true,
    /// using explicit options.
    func dismissCircleButtonToolbarIfNeeded(
        navigationOptions: CustomerCenterNavigationOptions,
        customDismiss: @escaping (() -> Void)
    ) -> some View {
        modifier(DismissCircleToolbar(
            options: navigationOptions,
            customDismiss: customDismiss
        ))
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

            DismissCircleButton(onDismiss: {})
        }.padding()
            .environment(\.appearance, CustomerCenterConfigData.standardAppearance)
            .environment(\.localization, CustomerCenterConfigData.default.localization)
    }

}

#endif
