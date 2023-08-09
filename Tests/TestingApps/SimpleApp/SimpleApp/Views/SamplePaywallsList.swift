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
        NavigationView {
            self.list(with: Self.loader)
                .navigationTitle("Test Paywalls")
        }
            .sheet(item: self.$display) { display in
                switch display {
                case let .template(template, mode):
                    switch mode {
                    case .fullScreen:
                        PaywallView(offering: Self.loader.offering(for: template),
                                    introEligibility: Self.introEligibility,
                                    purchaseHandler: .default())

                    case .card, .condensedCard:
                        CustomPaywall(offering: Self.loader.offering(for: template),
                                      mode: mode,
                                      introEligibility: Self.introEligibility,
                                      purchaseHandler: .default())
                    }

                case let .customFont(template):
                    PaywallView(offering: Self.loader.offering(for: template),
                                fonts: Self.customFontProvider,
                                introEligibility: Self.introEligibility,
                                purchaseHandler: .default())

                case let .customPaywall(mode):
                    CustomPaywall(mode: mode)

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
            ForEach(PaywallTemplate.allCases, id: \.rawValue) { template in
                Section(template.name) {
                    ForEach(PaywallViewMode.allCases, id: \.self) { mode in
                        Button {
                            self.display = .template(template, mode)
                        } label: {
                            TemplateLabel(name: mode.name)
                        }
                    }

                    Button {
                        self.display = .customFont(template)
                    } label: {
                        TemplateLabel(name: "Custom font")
                            .italic()
                    }
                }
            }

            Section("Other") {
                Button {
                    self.display = .customPaywall(.card)
                } label: {
                    TemplateLabel(name: "Custom Paywall with card")
                }

                Button {
                    self.display = .customPaywall(.condensedCard)
                } label: {
                    TemplateLabel(name: "Custom Paywall with condensed card")
                }

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

        case template(PaywallTemplate, PaywallViewMode)
        case customFont(PaywallTemplate)
        case customPaywall(PaywallViewMode)
        case defaultTemplate

    }

}

extension SamplePaywallsList.Display: Identifiable {

    public var id: String {
        switch self {
        case let .template(template, mode):
            return "template-\(template.rawValue)-\(mode)"

        case let .customFont(template):
            return "custom-font-" + template.rawValue

        case .customPaywall:
            return "custom-paywall"

        case .defaultTemplate:
            return "default"
        }
    }

}

extension PaywallTemplate {

    var name: String {
        switch self {
        case .template1:
            return "#1: Minimalist"
        case .template2:
            return "#2: Bold packages"
        case .template3:
            return "#3: Feature list"
        case .template4:
            return "#4: Horizontal packages"
        }
    }

}

private extension PaywallViewMode {

    var name: String {
        switch self {
        case .fullScreen:
            return "Fullscreen"
        case .card:
            return "Card"
        case .condensedCard:
            return "Condensed Card"
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
