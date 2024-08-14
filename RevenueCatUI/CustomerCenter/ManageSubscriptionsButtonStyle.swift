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

#if CUSTOMER_CENTER_ENABLED

import Foundation
import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ManageSubscriptionsButtonStyle: PrimitiveButtonStyle {

    @Environment(\.appearance) private var appearance: CustomerCenterConfigData.Appearance
    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: PrimitiveButtonStyleConfiguration) -> some View {
        let background = Color.from(colorInformation: appearance.buttonBackgroundColor, for: colorScheme)
        let textColor = Color.from(colorInformation: appearance.buttonTextColor, for: colorScheme)

        Button(action: { configuration.trigger() }, label: {
            configuration.label.frame(maxWidth: .infinity)
        })
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .applyIf(background != nil, apply: { $0.tint(background) })
        .applyIf(textColor != nil, apply: { $0.foregroundColor(textColor) })
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
            .environment(\.appearance, CustomerCenterConfigTestData.standardAppearance)
    }

}

#endif

#endif
