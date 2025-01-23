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

import RevenueCat
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

    @ViewBuilder
    var content: some View {
        ZStack {
            List {
                Section {
                    CompatibilityContentUnavailableView(
                        localization[.updateWarningTitle],
                        systemImage: "arrow.up.circle.fill",
                        description: Text(localization[.updateWarningDescription])
                    )
                }

                Section {
                    Button(localization[.updateWarningUpdate]) {
                        onUpdateAppClick()
                    }
                    .buttonStyle(ProminentButtonStyle())
                    .padding(.top, 4)

                    Button(localization[.updateWarningIgnore]) {
                        onContinueAnywayClick()
                    }
                    .buttonStyle(TextButtonStyle())
                }
                .listRowSeparator(.hidden)
            }
        }
        .dismissCircleButtonToolbar()
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                content
            }
        } else {
            NavigationView {
                content
            }
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
        Group {
            AppUpdateWarningView(
                onUpdateAppClick: {

                },
                onContinueAnywayClick: {

                }
            )
        }
    }

}

#endif

#endif
