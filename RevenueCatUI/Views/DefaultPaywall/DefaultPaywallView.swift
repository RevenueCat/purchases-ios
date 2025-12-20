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
//

#if canImport(AppKit)
import AppKit
#endif
import RevenueCat
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct DefaultPaywallView: View {

    init(
        handler: PurchaseHandler,
        warning: PaywallWarning? = nil,
        offering: Offering?,
        appName: String = AppStyleExtractor.getAppName(),
        iconDetailProvider: AppIconDetailProvider = AppIconDetailProvider()
    ) {
        self.handler = handler
        self.warning = warning
        self.appName = appName
        self.appIconDetailProvider = iconDetailProvider
        if let packages = offering?.availablePackages, !packages.isEmpty {
            self.selected = packages.first
            self.products = packages
        } else {
            self.products = []
        }
    }

    let handler: PurchaseHandler
    let appName: String

    @State private var warning: PaywallWarning?
    @State private var products: [Package]
    @State private var selected: Package?

    @Environment(\.colorScheme) var colorScheme

    @ObservedObject var appIconDetailProvider: AppIconDetailProvider

    // MARK: - Colors

    var iconColor: Color {
        if appIconDetailProvider.foundColors.isEmpty {
            return .accentColor
        }

        return selectColorWithBestContrast(
            from: appIconDetailProvider.foundColors,
            againstColor: colorScheme == .dark ? .black : .white
        )
    }

    var foregroundOnAccentColor: Color {
        if shouldShowWarning {
            return .white
        }

        return selectColorWithBestContrast(
            from: appIconDetailProvider.foundColors + [colorScheme == .dark ? .black : .white],
            againstColor: iconColor
        )
    }

    private var mainColor: Color {
        if shouldShowWarning {
            return .revenueCatBrandRed
        } else {
            return iconColor
        }
    }

    // MARK: - Warning

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

    // MARK: - Body

    var body: some View {
        VStack {
            warningTitle
            Spacer()

            if shouldShowWarning, let warning {
                DefaultPaywallWarning(warning: warning)
            } else {
                VStack(alignment: .center, spacing: 16) {
                    ZStack {
                        appIconDetailProvider.image
                            .resizable()
                            .blur(radius: 48)
                            .opacity(0.2)
                            .accessibilityHidden(true)
                        appIconDetailProvider.image
                            .resizable()
                            .clipShape(RoundedRectangle(cornerRadius: 31))
                            .accessibilityHidden(true)
                    }
                    .frame(width: 120, height: 120)
                    .shadow(color: mainColor.opacity(0.2), radius: 6, x: 0, y: 2)
                    .accessibilityAddTraits(.isImage)
                    .accessibilityLabel("App Icon Image")

                    Text(appName)
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
            // MARK: Footer Buttons
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
    }
}

// MARK: - Helpers

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

extension Color {
    static let revenueCatBrandRed = Color(red: 0.949, green: 0.329, blue: 0.357) // #f2545b
}
