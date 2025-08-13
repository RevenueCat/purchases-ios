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

@_spi(Internal) import RevenueCat
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
            ForEach(Array(items.enumerated()), id: \.element) { (offset, purchase) in
                Button {
                    action(purchase)
                } label: {
                    PurchaseInformationCardView(
                        purchaseInformation: purchase,
                        localization: localization,
                        accessibilityIdentifier: "purchase_card_\(offset)"
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

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct AccountDetailsSection: View {

    @Environment(\.colorScheme)
    private var colorScheme

    let originalPurchaseDate: Date?
    let originalAppUserId: String
    let localization: CustomerCenterConfigData.Localization

    init(
        originalPurchaseDate: Date?,
        originalAppUserId: String,
        localization: CustomerCenterConfigData.Localization
    ) {
        self.originalPurchaseDate = originalPurchaseDate
        self.originalAppUserId = originalAppUserId
        self.localization = localization
    }

    var body: some View {
#if DEBUG
        debugBody
#else
        if let originalPurchaseDate {
            ScrollViewSection(title: localization[.accountDetails]) {
                VStack {
                    CompatibilityLabeledContent(
                        localization[.dateWhenAppWasPurchased],
                        content: Self.dateFormatter.string(from: originalPurchaseDate)
                    )
                }
                .padding()
                .background(Color(colorScheme == .light
                                  ? UIColor.systemBackground
                                  : UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
#endif
    }

    var debugBody: some View {
        ScrollViewSection(title: localization[.accountDetails]) {
            VStack {
                if let originalPurchaseDate {
                    CompatibilityLabeledContent(
                        localization[.dateWhenAppWasPurchased],
                        content: Self.dateFormatter.string(from: originalPurchaseDate)
                    )

                    Divider()
                }

                userIdView
            }
            .padding()
            .background(Color(colorScheme == .light
                              ? UIColor.systemBackground
                              : UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }

    var userIdView: some View {
        CompatibilityLabeledContent(
            localization[.userId],
            content: originalAppUserId
        )
        .contextMenu {
            Button {
                UIPasteboard.general.string = originalAppUserId
            } label: {
                Text(localization[.copy])
                Image(systemName: "doc.on.clipboard")
            }
        }
    }

    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

#endif
