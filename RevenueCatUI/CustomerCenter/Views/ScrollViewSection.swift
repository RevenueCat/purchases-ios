//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ScrollViewSection.swift
//
//  Created by Facundo Menzella on 20/5/25.

import RevenueCat
import SwiftUI

#if os(iOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ScrollViewSection<Content: View>: View {
    @Environment(\.colorScheme)
    private var colorScheme

    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        Text(title.uppercased())
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .padding(.bottom, 12)

        content()
    }
}

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct PurchasesInformationSection: View {

    let title: String
    let items: [PurchaseInformation]
    let localization: CustomerCenterConfigData.Localization
    let action: (PurchaseInformation) -> Void

    var body: some View {
        ScrollViewSection(title: title) {
            ForEach(items) { purchase in
                Button {
                    action(purchase)
                } label: {
                    PurchaseInformationCardView(
                        purchaseInformation: purchase,
                        localization: localization
                    )
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                .padding(.bottom, 16)
            }

            Spacer().frame(height: 16)
        }
    }
}

#endif
