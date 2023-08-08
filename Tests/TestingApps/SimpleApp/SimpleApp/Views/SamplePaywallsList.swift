//
//  SamplePaywallsList.swift
//  SimpleApp
//
//  Created by Nacho Soto on 7/27/23.
//

#if DEBUG

import RevenueCat
@testable import RevenueCatUI
import SwiftUI

struct SamplePaywallsList: View {

    @State
    private var display: Display?

    var body: some View {
        self.list(with: Self.loader)
            .sheet(item: self.$display) { display in
                switch display {
                case let .template(template):
                    PaywallView(offering: Self.loader.offering(for: template),
                                introEligibility: Self.introEligibility,
                                purchaseHandler: .default())

                case let .customFont(template):
                    PaywallView(offering: Self.loader.offering(for: template),
                                fonts: Self.customFontProvider,
                                introEligibility: Self.introEligibility,
                                purchaseHandler: .default())

                case .defaultTemplate:
                    PaywallView(offering: Self.loader.offeringWithDefaultPaywall(),
                                introEligibility: Self.introEligibility,
                                purchaseHandler: .default())
                }
            }
            .navigationTitle("Paywalls")
    }

    private func list(with loader: SamplePaywallLoader) -> some View {
        List {
            Section("Templates") {
                ForEach(PaywallTemplate.allCases, id: \.rawValue) { template in
                    Button {
                        self.display = .template(template)
                    } label: {
                        TemplateLabel(name: template.name)
                    }
                }
            }

            Section("Custom Font") {
                ForEach(PaywallTemplate.allCases, id: \.rawValue) { template in
                    Button {
                        self.display = .customFont(template)
                    } label: {
                        TemplateLabel(name: template.name)
                    }
                }
            }

            Section("Other") {
                Button {
                    self.display = .defaultTemplate
                } label: {
                    TemplateLabel(name: "Default template")
                }
            }
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
    }

    private static let customFontProvider = CustomPaywallFontProvider(fontName: "Papyrus")
    private static let loader: SamplePaywallLoader = .init()
    private static let introEligibility: TrialOrIntroEligibilityChecker = .init { packages in
        return Dictionary(
            uniqueKeysWithValues: Set(packages)
                .map { package in
                    let result: IntroEligibilityStatus = package.storeProduct.hasIntroDiscount
                    ? Bool.random() ? .eligible : .ineligible
                    : .noIntroOfferExists

                    return (package, result)
                }
        )
    }

}

private struct TemplateLabel: View {

    var name: String

    var body: some View {
        Text(self.name)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
    }

}

// MARK: -

private extension SamplePaywallsList {

    enum Display {

        case template(PaywallTemplate)
        case customFont(PaywallTemplate)
        case defaultTemplate

    }

}

extension SamplePaywallsList.Display: Identifiable {

    public var id: String {
        switch self {
        case let .template(template):
            return "template-" + template.rawValue

        case let .customFont(template):
            return "custom-font-" + template.rawValue

        case .defaultTemplate:
            return "default"
        }
    }

}

extension PaywallTemplate {

    var name: String {
        switch self {
        case .template1:
            return "Minimalist"
        case .template2:
            return "Bold packages"
        case .template3:
            return "Feature list"
        case .template4:
            return "Horizontal packages"
        }
    }

}

#if DEBUG

struct SamplePaywallsList_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SamplePaywallsList()
        }
    }
}

#endif

#endif
