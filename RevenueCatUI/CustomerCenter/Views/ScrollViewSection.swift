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

#if os(iOS) || os(macOS)

@available(iOS 15.0, macOS 13.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct ScrollViewSection<Content: View>: View {
    @Environment(\.colorScheme)
    private var colorScheme

    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        #if os(macOS)
        // The Mac lays the Customer Center out as a grouped form, which draws its own headers.
        Section {
            content()
        } header: {
            Text(title)
        }
        #else
        Text(title.uppercased())
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .padding(.bottom, 12)

        content()
        #endif
    }
}

@available(iOS 15.0, macOS 13.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct PurchasesInformationSection: View {

    let title: String
    let items: [PurchaseInformation]
    let localization: CustomerCenterConfigData.Localization
    let action: (PurchaseInformation) -> Void

    var body: some View {
        #if os(macOS)
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
                }
                .customerCenterMacRow()
            }
        }
        #else
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
                    .padding(.horizontal)
                }
                .padding(.bottom, 16)
            }

            Spacer().frame(height: 16)
        }
        #endif
    }
}

// The card of the iOS layout; on the Mac the grouped form draws the section.
#if !os(macOS)

@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
private struct CardStyleModifier: ViewModifier {
    @Environment(\.colorScheme)
    private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding()
            #if compiler(>=5.9)
            .background(Color(colorScheme == .light
                              ? UIColor.systemBackground
                              : UIColor.secondarySystemBackground),
                        in: .rect(cornerRadius: CustomerCenterStylingUtilities.cornerRadius))
            #endif
            .padding(.horizontal)
    }
}

#endif

@available(iOS 15.0, macOS 13.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct AccountDetailsSection: View {

    @Environment(\.colorScheme)
    private var colorScheme

    let originalPurchaseDate: Date?
    let originalAppUserId: String
    let localization: CustomerCenterConfigData.Localization

    @State
    private var didCopyID = false
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
#if os(macOS)
        macBody
#elseif DEBUG
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
                .modifier(CardStyleModifier())
            }
        }
#endif
    }

    #if os(macOS)
    /// The account details as a section of the grouped form the Mac lays the Customer Center out
    /// in, one row each. Like on iOS, release builds show it only when there is a purchase date,
    /// and only debug builds add the user ID.
    @ViewBuilder
    var macBody: some View {
        #if DEBUG
        let showsUserID = true
        #else
        let showsUserID = false
        #endif
        if originalPurchaseDate != nil || showsUserID {
            Section {
                if let originalPurchaseDate {
                    LabeledContent(
                        localization[.dateWhenAppWasPurchased],
                        value: Self.dateFormatter.string(from: originalPurchaseDate)
                    )
                }
                if showsUserID {
                    userIdView
                }
            } header: {
                Text(localization[.accountDetails])
            }
        }
    }
    #endif

    #if !os(macOS)
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
            .modifier(CardStyleModifier())
        }
    }
    #endif

    @ViewBuilder
    var userIdView: some View {
        #if compiler(>=5.9)
        if #available(iOS 17.0, macOS 14.0, *) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(localization[.userId])
                    Spacer()
                    Button(localization[.copy], systemImage: didCopyID ? "checkmark" : "document.on.document") {
                        PlatformPasteboard.copy(originalAppUserId)
                        withAnimation {
                            didCopyID = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                self.didCopyID = false
                            }
                        }
                    }
                    .labelStyle(.iconOnly)
                    .frame(minHeight: 24)
                    .contentTransition(.symbolEffect(.replace))
                    .imageScale(.small)
                }

                Text(originalAppUserId)
                    .textSelection(.enabled)
                    .foregroundStyle(.secondary)
            }
        } else {
            HStack {
                Text(localization[.userId])
                Spacer()
                Text(originalAppUserId)
                    .textSelection(.enabled)
            }
            .contentShape(.rect(cornerRadius: 26))
            .contextMenu {
                Button(localization[.copy], systemImage: "document.on.document") {
                    PlatformPasteboard.copy(originalAppUserId)
                }
            }
        }
        #endif
    }
    private static var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }
}

#endif
