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

#if os(iOS) || os(macOS)

@available(iOS 15.0, macOS 13.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ProminentButtonStyle: PrimitiveButtonStyle {

    @Environment(\.appearance) private var appearance: CustomerCenterConfigData.Appearance
    @Environment(\.colorScheme) private var colorScheme
    private var needsLegacyBorderShape: Bool {
        #if compiler(>=6.2)
        if #available(iOS 26.0, macOS 26.0, *) { false } else { true }
        #else
        true
        #endif
    }

    /// `.roundedRectangle(radius:)` only exists from macOS 14.0 (iOS has had it since this type's
    /// iOS 15.0 floor); older macOS falls back to the un-parameterized shape.
    private var legacyBorderShape: ButtonBorderShape {
        if #available(macOS 14.0, *) {
            return .roundedRectangle(radius: 16)
        } else {
            return .roundedRectangle
        }
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
        .applyIf(needsLegacyBorderShape, apply: { $0.buttonBorderShape(legacyBorderShape) })
    }
}

// The card-style button of the iOS layout; the Mac lays its screens out as grouped forms.
#if !os(macOS)

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

#endif

@available(iOS 15.0, macOS 13.0, *)
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
        // macOS draws `Button(role: .close)` outside a toolbar as a text push button, so the Mac
        // keeps the circled glyph.
#if compiler(>=6.2) && !os(macOS)
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
                    .fill(Color(PlatformColor.secondarySystemFill))
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
                .fill(Color(PlatformColor.secondarySystemFill))
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

@available(iOS 15.0, macOS 13.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct DismissCircleToolbar: ViewModifier {
    @Environment(\.dismiss)
    private var dismiss

    let options: CustomerCenterNavigationOptions

    /// The screen's title, drawn next to the button on macOS (see `drawsTitleInCloseRow`).
    /// Ignored on iOS, where screens title themselves in the navigation bar.
    let title: String?

    private var customDismiss: (() -> Void)?

    /// macOS: float the button over the content's corner instead of heading a row above it, for
    /// full-bleed content (a paywall) whose own background should reach the top edge.
    private let floatsOverContent: Bool

    init(
        options: CustomerCenterNavigationOptions,
        title: String? = nil,
        floatsOverContent: Bool = false,
        customDismiss: (() -> Void)?
    ) {
        self.options = options
        self.title = title
        self.floatsOverContent = floatsOverContent
        self.customDismiss = customDismiss
    }

    func body(content: Content) -> some View {
        #if compiler(>=5.9)
        if showsCloseButton {
            let onClose = customDismiss ?? options.onCloseHandler ?? { dismiss() }
            #if os(macOS)
            // A macOS sheet has no navigation bar and sinks toolbar items to its bottom edge, so the
            // button heads a row in the top-leading corner, answers Esc and carries the title. The
            // row sits above scrolling content, never over it: without the macOS 26 edge effect,
            // content scrolled under a safe-area inset or bar draws through it.
            if floatsOverContent {
                content.overlay(alignment: .topLeading) {
                    closeRow(onClose: onClose)
                }
            } else {
                VStack(spacing: 0) {
                    closeRow(onClose: onClose)
                    content
                }
            }
            #else
            content
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        DismissCircleButton(onDismiss: onClose)
                    }
                }
            #endif
        } else {
            content
        }
        #else
        content
        #endif
    }

    #if os(macOS)
    private func closeRow(onClose: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            DismissCircleButton(onDismiss: onClose)
                .keyboardShortcut(.cancelAction)
            if let title {
                Text(title)
                    .font(.headline)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    #endif

    /// iOS shows the button only when the options ask for it, since a sheet there can also be
    /// swiped away. A macOS sheet cannot, so the nested sheets (the only callers passing a
    /// custom dismiss) always get it there.
    private var showsCloseButton: Bool {
        #if os(macOS)
        return options.shouldShowCloseButton || customDismiss != nil
        #else
        return options.shouldShowCloseButton
        #endif
    }
}

@available(iOS 15.0, macOS 13.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension View {
    /// Adds a toolbar with a dismiss button if `options.shouldShowCloseButton` is true,
    /// using explicit options.
    func dismissCircleButtonToolbarIfNeeded(
        navigationOptions: CustomerCenterNavigationOptions,
        title: String? = nil,
        floatsOverContent: Bool = false
    ) -> some View {
        modifier(DismissCircleToolbar(
            options: navigationOptions,
            title: title,
            floatsOverContent: floatsOverContent,
            customDismiss: nil
        ))
    }

    /// Adds a toolbar with a dismiss button if `navigationOptions.shouldShowCloseButton` is true,
    /// using explicit options.
    func dismissCircleButtonToolbarIfNeeded(
        navigationOptions: CustomerCenterNavigationOptions,
        title: String? = nil,
        floatsOverContent: Bool = false,
        customDismiss: @escaping (() -> Void)
    ) -> some View {
        modifier(DismissCircleToolbar(
            options: navigationOptions,
            title: title,
            floatsOverContent: floatsOverContent,
            customDismiss: customDismiss
        ))
    }
}

@available(iOS 15.0, macOS 13.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
extension CustomerCenterNavigationOptions {

    /// Whether the Customer Center's root puts its title in the close button's row instead of a
    /// navigation title, which a macOS sheet would draw as a second bar above that row. Only the
    /// root has the row, so `CustomerCenterView` hands this to it alone; pushed screens keep theirs.
    var drawsTitleInCloseRow: Bool {
        #if os(macOS)
        return shouldShowCloseButton
        #else
        return false
        #endif
    }

}

#if os(macOS)

@available(macOS 13.0, *)
extension View {

    /// Makes a `Button` read as a row of a grouped macOS `Form`, the way the Customer Center lays
    /// out its screens on the Mac. A `Button` inside a macOS form draws itself as a bordered push
    /// button; this style gives the row back and makes all of it clickable.
    func customerCenterMacRow() -> some View {
        self.buttonStyle(CustomerCenterMacRowButtonStyle())
    }

}

/// A plain row button whose whole row takes the click, once per click gesture. The content shape
/// goes on the label: on the `Button` it leaves the blank part of the row dead (macOS 27). A Mac
/// button fires on every click of a double-click, so the second one is dropped.
@available(macOS 13.0, *)
private struct CustomerCenterMacRowButtonStyle: PrimitiveButtonStyle {

    func makeBody(configuration: PrimitiveButtonStyleConfiguration) -> some View {
        Button(role: configuration.role) {
            if let event = NSApp.currentEvent,
               event.type == .leftMouseUp || event.type == .leftMouseDown,
               event.clickCount > 1 {
                return
            }
            configuration.trigger()
        } label: {
            configuration.label
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

}

/// The label of a Customer Center row on macOS: its title across the row and, for a row that
/// leads to another screen, a chevron at the trailing edge.
@available(macOS 13.0, *)
struct CustomerCenterMacRowLabel: View {

    let title: String
    var showsChevron: Bool = false

    var body: some View {
        HStack {
            Text(title)
            Spacer(minLength: 0)
            if showsChevron {
                Image(systemName: "chevron.forward")
                    .font(.footnote.weight(.semibold))
                    // Not `.tertiary`, which under a tinted title comes out as a faded tint.
                    .foregroundStyle(Color(nsColor: .tertiaryLabelColor))
                    .accessibilityHidden(true)
            }
        }
    }

}

#endif

@available(iOS 15.0, macOS 13.0, *)
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
