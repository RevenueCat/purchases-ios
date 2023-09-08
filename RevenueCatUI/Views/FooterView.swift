//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  FooterView.swift
//  
//  Created by Nacho Soto on 7/20/23.

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
struct FooterView: View {

    @Environment(\.userInterfaceIdiom)
    private var interfaceIdiom

    var configuration: PaywallData.Configuration
    var mode: PaywallViewMode
    var fonts: PaywallFontProvider
    var color: Color
    var boldPreferred: Bool
    var purchaseHandler: PurchaseHandler
    var displayingAllPlans: Binding<Bool>?
    static let buttonMinHeight: CGFloat = 44

    init(
        configuration: TemplateViewConfiguration,
        bold: Bool = true,
        purchaseHandler: PurchaseHandler,
        displayingAllPlans: Binding<Bool>? = nil
    ) {
        self.init(
            configuration: configuration.configuration,
            mode: configuration.mode,
            fonts: configuration.fonts,
            color: configuration.colors.text1Color,
            purchaseHandler: purchaseHandler,
            displayingAllPlans: displayingAllPlans
        )
    }

    fileprivate init(
        configuration: PaywallData.Configuration,
        mode: PaywallViewMode,
        fonts: PaywallFontProvider,
        color: Color,
        bold: Bool = true,
        purchaseHandler: PurchaseHandler,
        displayingAllPlans: Binding<Bool>?
    ) {
        self.configuration = configuration
        self.mode = mode
        self.fonts = fonts
        self.color = color
        self.boldPreferred = bold
        self.purchaseHandler = purchaseHandler
        self.displayingAllPlans = displayingAllPlans
    }

    var body: some View {
        HStack {
            if self.mode.displayAllPlansButton, let binding = self.displayingAllPlans {
                Self.allPlansButton(binding)

                if self.configuration.displayRestorePurchases || self.hasTOS || self.hasPrivacy {
                    self.separator
                }
            }

            if self.configuration.displayRestorePurchases {
                RestorePurchasesButton(purchaseHandler: self.purchaseHandler)

                if self.hasTOS || self.hasPrivacy {
                    self.separator
                }
            }

            if let url = self.configuration.termsOfServiceURL {
                LinkButton(
                    url: url,
                    titles: "Terms and conditions", "Terms"
                )

                if self.hasPrivacy {
                    self.separator
                }
            }

            if let url = self.configuration.privacyURL {
                LinkButton(
                    url: url,
                    titles: "Privacy policy", "Privacy"
                )
            }
        }
        .foregroundColor(self.color)
        .font(self.fonts.font(for: self.font).weight(self.fontWeight))
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .padding(.bottom, 5)
        .dynamicTypeSize(...Constants.maximumDynamicTypeSize)
        #if targetEnvironment(macCatalyst)
        .buttonStyle(.plain)
        #endif
    }

    private static func allPlansButton(_ binding: Binding<Bool>) -> some View {
        Button {
            withAnimation(Constants.toggleAllPlansAnimation) {
                binding.wrappedValue.toggle()
            }
        } label: {
            Text("All subscriptions", bundle: .module)
        }
        .frame(minHeight: FooterView.buttonMinHeight)
    }

    private var separator: some View {
        SeparatorView(bold: self.bold)
    }

    private var bold: Bool {
        return self.boldPreferred && self.interfaceIdiom != .pad
    }

    private var hasTOS: Bool { self.configuration.termsOfServiceURL != nil }
    private var hasPrivacy: Bool { self.configuration.privacyURL != nil }
    private var fontWeight: Font.Weight { self.bold ? .bold : .regular }

    fileprivate var font: Font.TextStyle {
        return self.interfaceIdiom == .pad
        ? .callout
        : .caption
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct SeparatorView: View {

    var bold: Bool

    var body: some View {
        Image(systemName: "circle.fill")
            .font(.system(size: self.bold ? self.boldSeparatorSize : self.separatorSize))
            .accessibilityHidden(true)
    }

    @ScaledMetric(relativeTo: .caption)
    private var separatorSize: CGFloat = 4

    @ScaledMetric(relativeTo: .caption)
    private var boldSeparatorSize: CGFloat = 5
}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct RestorePurchasesButton: View {

    let purchaseHandler: PurchaseHandler

    @State
    private var displayRestoredAlert = false

    var body: some View {
        AsyncButton {
            _ = try await self.purchaseHandler.restorePurchases()
            self.displayRestoredAlert = true
        } label: {
            if #available(iOS 16.0, macOS 13.0, tvOS 16.0, *) {
                ViewThatFits {
                    Text("Restore purchases", bundle: .module)
                    Text("Restore", bundle: .module)
                }
            } else {
                Text("Restore purchases", bundle: .module)
            }
        }
        .frame(minHeight: FooterView.buttonMinHeight)
        .buttonStyle(.plain)
        .alert(isPresented: self.$displayRestoredAlert) {
            Alert(title: Text("Purchases restored successfully!", bundle: .module))
        }
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
private struct LinkButton: View {

    @Environment(\.locale)
    private var locale

    let url: URL
    let titles: [String]

    init(url: URL, titles: String...) {
        self.url = url
        self.titles = titles
    }

    var body: some View {
        let bundle = Localization.localizedBundle(self.locale)

        if #available(iOS 16.0, macOS 13.0, tvOS 16.0, *) {
            ViewThatFits {
                ForEach(self.titles, id: \.self) { title in
                    self.link(for: title, bundle: bundle)
                }
            }
        } else if let first = self.titles.first {
            self.link(for: first, bundle: bundle)
        }
    }

    private func link(for title: String, bundle: Bundle) -> some View {
        Link(
            bundle.localizedString(
                forKey: title,
                value: nil,
                table: nil
            ),
            destination: self.url
        )
        .frame(minHeight: FooterView.buttonMinHeight)
    }
}

// MARK: - Previews

#if DEBUG && canImport(SwiftUI) && canImport(UIKit)

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(watchOS, unavailable)
@available(macOS, unavailable)
struct Footer_Previews: PreviewProvider {

    static var previews: some View {
        Self.create(
            displayRestorePurchases: false
        )
        .previewDisplayName("Empty")

        Self.create(
            displayRestorePurchases: true
        )
        .previewDisplayName("Only Restore")

        Self.create(
            displayRestorePurchases: false,
            termsOfServiceURL: URL(string: "https://revenuecat.com/tos")!
        )
        .previewDisplayName("TOS")

        Self.create(
            displayRestorePurchases: true,
            termsOfServiceURL: URL(string: "https://revenuecat.com/tos")!
        )
        .previewDisplayName("Restore + TOS")

        Self.create(
            displayRestorePurchases: true,
            termsOfServiceURL: URL(string: "https://revenuecat.com/tos")!,
            privacyURL: URL(string: "https://revenuecat.com/tos")!
        )
        .previewDisplayName("All")

        Self.create(
            displayRestorePurchases: true,
            termsOfServiceURL: URL(string: "https://revenuecat.com/tos")!,
            privacyURL: URL(string: "https://revenuecat.com/tos")!,
            bold: false
        )
        .previewDisplayName("Not bold")
    }

    private static func create(
        displayRestorePurchases: Bool = true,
        termsOfServiceURL: URL? = nil,
        privacyURL: URL? = nil,
        bold: Bool = true
    ) -> some View {
        FooterView(
            configuration: .init(
                packages: [],
                images: .init(),
                colors: .init(light: TestData.lightColors, dark: TestData.darkColors),
                displayRestorePurchases: displayRestorePurchases,
                termsOfServiceURL: termsOfServiceURL,
                privacyURL: privacyURL
            ),
            mode: .fullScreen,
            fonts: DefaultPaywallFontProvider(),
            color: TestData.colors.text1Color,
            bold: bold,
            purchaseHandler: PreviewHelpers.purchaseHandler,
            displayingAllPlans: .constant(false)
        )
    }

}

#endif
