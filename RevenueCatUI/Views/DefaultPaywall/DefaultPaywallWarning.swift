//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DefaultPaywallWarning.swift
//
//  Created by Jacob Zivan Rakidzich on 12/14/25.

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct DefaultPaywallWarning: View {
    let warning: PaywallWarning

    var body: some View {
        VStack(alignment: .center, spacing: 16) {

            Image("default-paywall", bundle: .module)
                .accessibilityHidden(true)

            VStack(alignment: .center, spacing: 8) {
                Text(warning.title)
                    .font(.title3)
                    .bold()
                Text(warning.bodyText)
                    .font(.subheadline)
            }
            if let url = warning.helpURL {
                let link = Link(destination: url) {
                    Text("Go to Dashboard")
                        .bold()
                }.buttonStyle(.bordered)

                if #available(watchOS 9.0, *) {
                    link.tint(.revenueCatBrandRed)
                } else {
                    link.foregroundStyle(Color.revenueCatBrandRed)
                }
            }

        }
        .multilineTextAlignment(.center)
    }
}
