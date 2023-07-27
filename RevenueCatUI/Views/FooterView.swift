//
//  FooterView.swift
//  
//
//  Created by Nacho Soto on 7/20/23.
//

import RevenueCat
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct FooterView: View {

    var configuration: PaywallData.Configuration
    var color: Color
    var purchaseHandler: PurchaseHandler

    var body: some View {
        HStack {
            if self.configuration.displayRestorePurchases {
                RestorePurchasesButton(purchaseHandler: self.purchaseHandler)

                self.separator
                    .hidden(if: !self.hasTOS && !self.hasPrivacy)
            }

            if let url = self.configuration.termsOfServiceURL {
                LinkButton(
                    url: url,
                    titles: "Terms and conditions", "Terms"
                )

                self.separator
                    .hidden(if: !self.hasPrivacy)
            }

            if let url = self.configuration.privacyURL {
                LinkButton(
                    url: url,
                    titles: "Privacy policy", "Privacy"
                )
            }
        }
        .foregroundColor(self.color)
        .font(.caption.bold())
        .padding(.horizontal)
    }

    private var separator: some View {
        Image(systemName: "circle.fill")
            .font(.system(size: 5))
    }

    private var hasTOS: Bool { self.configuration.termsOfServiceURL != nil }
    private var hasPrivacy: Bool { self.configuration.privacyURL != nil }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
private struct RestorePurchasesButton: View {

    let purchaseHandler: PurchaseHandler

    @State
    private var restored = false

    var body: some View {
        AsyncButton {
            _ = try await self.purchaseHandler.restorePurchases()
            self.restored = true
        } label: {
            ViewThatFits {
                Text("Restore purchases", bundle: .module)
                Text("Restore", bundle: .module)
            }
        }
        .buttonStyle(.plain)
        .alert(isPresented: self.$restored) {
            Alert(title: Text("Purchases restored successfully!", bundle: .module))
        }
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
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

        ViewThatFits {
            ForEach(self.titles, id: \.self) { title in
                Link(
                    bundle.localizedString(
                        forKey: title,
                        value: nil,
                        table: nil
                    ),
                    destination: self.url
                )
            }
        }
    }

}

#if DEBUG && canImport(SwiftUI) && canImport(UIKit)

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
@available(watchOS, unavailable)
@available(macOS, unavailable)
@available(macCatalyst, unavailable)
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
    }

    private static func create(
        displayRestorePurchases: Bool = true,
        termsOfServiceURL: URL? = nil,
        privacyURL: URL? = nil
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
            color: TestData.colors.foregroundColor,
            purchaseHandler: Self.handler
        )
    }

    private static let handler: PurchaseHandler =
        .mock()
        .with(delay: .seconds(0.5))

}

#endif
