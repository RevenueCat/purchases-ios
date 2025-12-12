//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DefaultPaywallView.swift
//
//  Created by Jacob Zivan Rakidzich on 12/11/25.

#if canImport(AppKit)
import AppKit
#endif

import RevenueCat
import SwiftUI

fileprivate extension Color {
    static let revenueCatBrandRed = Color(red: 0.949, green: 0.329, blue: 0.357) // #f2545b
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct DefaultPaywallView: View {

    init(handler: PurchaseHandler, warning: PaywallWarning? = nil, offering: Offering?) {
        self.handler = handler
        self.warning = warning
        if let packages = offering?.availablePackages, !packages.isEmpty {
            self.products = packages
        } else {
            self.warning = .noProducts(CocoaError.error(.coderInvalidValue))
            self.products = []
        }
    }

    let handler: PurchaseHandler

    @State private var warning: PaywallWarning?
    @State private var products: [Package]
    @State private var selected: Package?

    @State var colors: [Color] = []

    var iconColor: Color {
        if colors.isEmpty {
            return .accentColor
        }

        return selectColorWithBestContrast(from: colors, againstColor: colorScheme == .dark ? .black : .white)
    }

    var foregroundOnAccentColor: Color {
        if shouldShowWarning {
            return .white
        }

        return selectColorWithBestContrast(
            from: colors + [colorScheme == .dark ? .black : .white],
            againstColor: iconColor
        )
    }

    @Environment(\.colorScheme) var colorScheme

    private var mainColor: Color {
        if shouldShowWarning {
            return .revenueCatBrandRed
        } else {
            return iconColor
        }
    }

    var shouldShowWarning: Bool {
        var showWarning = false
        #if DEBUG
        showWarning = (warning != nil)
        #endif
        return showWarning
    }

    @ViewBuilder
    var warningTitle: some View {
        if shouldShowWarning {
            Text("RevenueCat Paywalls")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    var body: some View {
        VStack {
            warningTitle
            Spacer()

            if shouldShowWarning, let warning {
                DefaultPaywallWarning(warning: warning)
            } else {
                VStack(alignment: .center, spacing: 16) {
                    let image = AppStyleExtractor.getAppIcon()
                    ZStack {
                        image
                            .resizable()
                            .blur(radius: 48)
                            .opacity(0.2)
                            .accessibilityHidden(true)
                        image
                            .resizable()
                            .clipShape(RoundedRectangle(cornerRadius: 31))
                            .accessibilityHidden(true)
                    }
                    .frame(width: 120, height: 120)
                    .shadow(color: mainColor.opacity(0.2), radius: 6, x: 0, y: 2)
                    .accessibilityAddTraits(.isImage)
                    .accessibilityLabel("App Icon Image")

                    Text(AppStyleExtractor.getAppName())
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
            Spacer()

            VStack {
                ForEach(products) { product in
                    DefaultProductCell(
                        product: product,
                        accentColor: mainColor,
                        selectedFontColor: foregroundOnAccentColor,
                        selected: $selected
                    )
                }
            }
        }
        .padding()
        .safeAreaInset(edge: .bottom) {
            if !products.isEmpty {
                VStack {
                    let purchaseButton = Button {
                        if let selected {
                            Task(priority: .userInitiated) {
                                try await handler.purchase(package: selected)
                            }
                        }
                    } label: {
                        Text("Purchase")
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundStyle(foregroundOnAccentColor)
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: 480) // For iPad or macOS

                    if #available(watchOS 9.0, *) {
                        purchaseButton
                            #if !os(tvOS)
                            .controlSize(.large)
                            #endif
                    } else {
                        purchaseButton
                    }

                    let restoreButton = Button {
                        Task(priority: .userInitiated) {
                            try await handler.restorePurchases()
                        }
                    } label: {
                        Text("Restore Purchases")
                    }
                        .padding(.top, 8)

                    if #available(watchOS 9.0, *) {
                        restoreButton
                            #if !os(tvOS)
                            .controlSize(.large)
                            #endif
                            .tint(Color.primary)
                    } else {
                        restoreButton
                    }
                }
                .padding()
            }

        }
        .fillWithReadableContentWidth()
        .background {
            LinearGradient(colors: [
                mainColor.opacity(0.2),
                mainColor.opacity(0)
            ], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        }
        #if !os(watchOS)
        .tint(mainColor)
        #endif
        .task {
            colors = await AppStyleExtractor.getProminentColorsFromAppIcon()
        }
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct DefaultProductCell: View {
    let product: Package
    let accentColor: Color
    let selectedFontColor: Color
    @Binding var selected: Package?

    private var isSelected: Bool {
        selected == product
    }

    var body: some View {
        Button {
            withAnimation {
                selected = product
            }
        } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .opacity(isSelected ? 1 : 0.5)
                    .accessibilityHidden(true)
                Text(product.storeProduct.localizedTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(product.localizedPriceString)
                    .font(.subheadline)
                    .monospacedDigit()
            }
            .foregroundColor(isSelected ? selectedFontColor : Color.primary)
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(isSelected ? accentColor : .secondary.opacity(0.3))
            }
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        #if os(macOS)
        .buttonStyle(.plain)
        #endif
        .frame(maxWidth: 560)
    }
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
private struct DefaultPaywallWarning: View {
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

extension View {
    // centers content but doesn't allow it to get too wide, this looks better on full screens like an ipad
    func fillWithReadableContentWidth() -> some View {
        self
        // UIKit used to have readable content guides, they started around 624 pixels and scaled up with dynamic fonts
        // This is just a sensible default that is close to the readable guide
            .frame(maxWidth: 630)
            .frame(maxWidth: .infinity)
    }
}
