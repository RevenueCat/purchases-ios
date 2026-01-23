//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  AppUpdateWarningView.swift
//
//  Created by JayShortway on 16/08/2024.

@_spi(Internal) import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct AppUpdateWarningView: View {

    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance

    @Environment(\.colorScheme)
    private var colorScheme

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization

    let onUpdateAppClick: () -> Void
    let onContinueAnywayClick: () -> Void

    init(onUpdateAppClick: @escaping () -> Void, onContinueAnywayClick: @escaping () -> Void) {
        self.onUpdateAppClick = onUpdateAppClick
        self.onContinueAnywayClick = onContinueAnywayClick
    }

    var body: some View {
        Color(colorScheme == .light ? UIColor.secondarySystemBackground : UIColor.systemBackground)
            .ignoresSafeArea()
            .overlay {
                VStack(alignment: .center, content: {
                    CompatibilityContentUnavailableView(
                        localization[.updateWarningTitle],
                        systemImage: "arrow.up.circle.fill",
                        description: Text(localization[.updateWarningDescription])
                    )
                    .padding(.horizontal, 16)
                    .padding(.vertical, 24)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                Color(colorScheme == .light
                                      ? UIColor.systemBackground
                                      : UIColor.secondarySystemBackground)
                            )
                            .padding(.horizontal, 24)
                            .padding(.top, 24)
                    )

                    Spacer()

                    VStack(alignment: .center, spacing: 24) {
                        Button(localization[.updateWarningUpdate]) {
                            onUpdateAppClick()
                        }
                        .buttonStyle(ProminentButtonStyle())

                        Button(localization[.updateWarningIgnore]) {
                            onContinueAnywayClick()
                        }
                        .buttonStyle(TextButtonStyle())
                    }
                    .padding(.horizontal, 24)
                })
                .scrollableIfNecessaryWhenAvailableForV1(.vertical)
            }
    }
}

/// This is a workaround to be able to have 2 buttons in a single Section. Buttons without ButtonStyles make the entire
/// section clickable.
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct TextButtonStyle: PrimitiveButtonStyle {

    func makeBody(configuration: PrimitiveButtonStyleConfiguration) -> some View {
        Button(action: { configuration.trigger() }, label: {
            configuration.label.frame(maxWidth: .infinity)
        })
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct AppUpdateWarningView_Previews: PreviewProvider {

    static var previews: some View {
        NavigationView {
            AppUpdateWarningView(
                onUpdateAppClick: { },
                onContinueAnywayClick: { }
            )
            .environment(\.colorScheme, .light)
        }

        NavigationView {
            AppUpdateWarningView(
                onUpdateAppClick: { },
                onContinueAnywayClick: { }
            )
            .environment(\.colorScheme, .dark)
        }
    }
}

#endif

#endif
