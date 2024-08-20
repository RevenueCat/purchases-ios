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

#if CUSTOMER_CENTER_ENABLED

import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct AppUpdateWarningView: View {
    let onUpdateAppClick: () -> Void
    let onContinueAnywayClick: () -> Void

    @Environment(\.dismiss)
    var dismiss

    @Environment(\.localization)
    private var localization: CustomerCenterConfigData.Localization
    @Environment(\.appearance)
    private var appearance: CustomerCenterConfigData.Appearance
    @Environment(\.colorScheme)
    private var colorScheme

    @ViewBuilder
    var content: some View {
        ZStack {
            if let background = Color.from(colorInformation: appearance.backgroundColor, for: colorScheme) {
                background.edgesIgnoringSafeArea(.all)
            }
            let textColor = Color.from(colorInformation: appearance.textColor, for: colorScheme)

            VStack {
                CompatibilityContentUnavailableView(
                    localization.commonLocalizedString(for: .updateWarningTitle),
                    systemImage: "arrowshape.up.circle.fill",
                    description: Text(localization.commonLocalizedString(for: .updateWarningDescription))
                )

                Button(localization.commonLocalizedString(for: .updateWarningUpdate)) {
                    onUpdateAppClick()
                }
                .buttonStyle(ProminentButtonStyle())
                .padding(.bottom)

                Button(localization.commonLocalizedString(for: .updateWarningIgnore)) {
                    onContinueAnywayClick()
                }
            }
            .padding(.horizontal)
            .applyIf(textColor != nil, apply: { $0.foregroundColor(textColor) })
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                DismissCircleButton {
                    dismiss()
                }
            }
        }
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

#endif
