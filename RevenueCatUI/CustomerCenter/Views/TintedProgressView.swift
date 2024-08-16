//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TintedProgressView.swift
//
//  Created by Cesar de la Vega on 19/7/24.

#if CUSTOMER_CENTER_ENABLED

import Foundation
import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct TintedProgressView: View {

    @Environment(\.appearance) private var appearance: CustomerCenterConfigData.Appearance
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ProgressView()
            .controlSize(.regular)
            .tint(Color.from(colorInformation: self.appearance.buttonTextColor, for: self.colorScheme))
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct TintedProgressView_Previews: PreviewProvider {

    static var previews: some View {
        TintedProgressView()
            .environment(\.appearance, CustomerCenterConfigTestData.standardAppearance)
    }

}

#endif

#endif
