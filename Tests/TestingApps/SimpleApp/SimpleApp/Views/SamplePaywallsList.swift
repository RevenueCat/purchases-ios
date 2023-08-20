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

                    case .overlay, .condensedOverlay:
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

                case .missingPaywall:
                    PaywallView(offering: Self.loader.offeringWithDefaultPaywall(),
                                introEligibility: Self.introEligibility,
                                purchaseHandler: .default())

                case .unrecognizedPaywall:
                    PaywallView(offering: Self.loader.offeringWithUnrecognizedPaywall(),
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
                            TemplateLabel(name: mode.name, icon: mode.icon)
                        }
                    }

                    Button {
                        self.display = .customFont(template)
                    } label: {
                        TemplateLabel(name: "Custom font", icon: "textformat")
                            .font(.body.italic())
                    }
                }
            }

            Section("Other") {
                Button {
                    self.display = .customPaywall(.overlay)
                } label: {
                    TemplateLabel(name: "Custom + card",
                                  icon: PaywallViewMode.overlay.icon)
                }

                Button {
                    self.display = .customPaywall(.condensedOverlay)
                } label: {
                    TemplateLabel(name: "Custom + condensed card",
                                  icon: PaywallViewMode.condensedOverlay.icon)
                }

                Button {
                    self.display = .missingPaywall
                } label: {
                    TemplateLabel(name: "Offering with no paywall", icon: "exclamationmark.triangle")
                }

                Button {
                    self.display = .unrecognizedPaywall
                } label: {
                    TemplateLabel(name: "Unrecognized paywall", icon: "exclamationmark.triangle")
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
    var icon: String

    var body: some View {
        Label(self.name, systemImage: self.icon)
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
        case missingPaywall
        case unrecognizedPaywall

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

        case .missingPaywall:
            return "missing"

        case .unrecognizedPaywall:
            return "unrecognized"
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

    var icon: String {
        switch self {
        case .fullScreen: return "iphone"
        case .overlay: return "lanyardcard"
        case .condensedOverlay: return "ruler"
        }
    }

    var name: String {
        switch self {
        case .fullScreen:
            return "Fullscreen"
        case .overlay:
            return "Card"
        case .condensedOverlay:
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
