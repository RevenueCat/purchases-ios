//
//  SamplePaywallsList.swift
//  PaywallsPreview
//
//  Created by Nacho Soto on 7/27/23.
//



import RevenueCat
import RevenueCatUI
import SwiftUI

struct SamplePaywallsList: View {

    @State
    private var display: Display?

    @State
    private var presentingCustomerCenter: Bool = false

    var body: some View {
        NavigationView {
            self.list(with: Self.loader)
                .navigationTitle("Example Paywalls")
        }
        .sheet(item: self.$display) { display in
            self.view(for: display)
        }
        .navigationTitle("Paywalls")
        .navigationViewStyle(StackNavigationViewStyle())
    }

    @ViewBuilder
    private func view(for display: Display) -> some View {
        switch display {
        case let .template(template, mode):
            switch mode {
            case .fullScreen:
                PaywallView(configuration: .init(
                    offering: Self.loader.offering(for: template),
                    customerInfo: Self.loader.customerInfo,
                    displayCloseButton: Self.displayCloseButton,
                    introEligibility: Self.introEligibility
                ))

            #if !os(watchOS)
            case .footer, .condensedFooter:
                CustomPaywall(offering: Self.loader.offering(for: template),
                              customerInfo: Self.loader.customerInfo,
                              condensed: mode == .condensedFooter,
                              introEligibility: Self.introEligibility)
            #endif
            }

        case let .customFont(template):
            PaywallView(
                configuration: .init(
                    offering: Self.loader.offering(for: template),
                    customerInfo: Self.loader.customerInfo,
                    fonts: Self.customFontProvider,
                    displayCloseButton: Self.displayCloseButton,
                    introEligibility: Self.introEligibility
                )
            )

        #if !os(watchOS)
        case let .customPaywall(mode):
            CustomPaywall(customerInfo: Self.loader.customerInfo,
                          condensed: mode == .condensedFooter)
        #endif

        case .missingPaywall:
            PaywallView(
                configuration: .init(
                    offering: Self.loader.offeringWithDefaultPaywall(),
                    customerInfo: Self.loader.customerInfo,
                    introEligibility: Self.introEligibility
                )
            )

        case .unrecognizedPaywall:
            PaywallView(
                configuration: .init(
                    offering: Self.loader.offeringWithUnrecognizedPaywall(),
                    customerInfo: Self.loader.customerInfo,
                    introEligibility: Self.introEligibility
                )
            )
        case .customerCenter:
            CustomerCenterView(customerCenterActionHandler: self.handleCustomerCenterAction)
        #if PAYWALL_COMPONENTS
        case .componentPaywall(let data):
            PaywallView(configuration: .init(
                offering: Self.loader.offering(with: data),
                customerInfo: Self.loader.customerInfo,
                displayCloseButton: Self.displayCloseButton,
                introEligibility: Self.introEligibility
            ))
        #endif
        }

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
                #if !os(watchOS)
                Button {
                    self.display = .customPaywall(.footer)
                } label: {
                    TemplateLabel(name: "Custom + footer",
                                  icon: PaywallViewMode.footer.icon)
                }

                Button {
                    self.display = .customPaywall(.condensedFooter)
                } label: {
                    TemplateLabel(name: "Custom + condensed footer",
                                  icon: PaywallViewMode.condensedFooter.icon)
                }
                #endif

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

            #if os(iOS)
            Section("Customer Center") {
                Button {
                    self.display = .customerCenter
                } label: {
                    TemplateLabel(name: "SwiftUI", icon: "person.fill.questionmark")
                }

                Button {
                    self.presentingCustomerCenter = true
                } label: {
                    TemplateLabel(name: "Sheet", icon: "person.fill")
                }
            }
            #endif
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
        #if os(iOS)
        .presentCustomerCenter(isPresented: self.$presentingCustomerCenter, customerCenterActionHandler: self.handleCustomerCenterAction) {
            self.presentingCustomerCenter = false
        }
        #endif
    }

    #if os(watchOS)
    private static let customFontProvider = CustomPaywallFontProvider(fontName: "Courier New")
    private static let displayCloseButton = false
    #else
    private static let customFontProvider = CustomPaywallFontProvider(fontName: "Papyrus")
    private static let displayCloseButton = true
    #endif

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

#if os(iOS)

extension SamplePaywallsList {

    func handleCustomerCenterAction(action: CustomerCenterAction) {
        switch action {
        case .restoreCompleted(_):
            print("CustomerCenter: restoreCompleted")
        case .restoreStarted:
            print("CustomerCenter: restoreStarted")
        case .restoreFailed(_):
            print("CustomerCenter: restoreFailed")
        case .showingManageSubscriptions:
            print("CustomerCenter: showingManageSubscriptions")
        case .refundRequestStarted(let productId):
            print("CustomerCenter: refundRequestStarted. ProductId: \(productId)")
        case .refundRequestCompleted(let status):
            print("CustomerCenter: refundRequestCompleted. Result: \(status)")
        case .feedbackSurveyCompleted(let surveyOptionID):
            print("CustomerCenter: feedbackSurveyCompleted. Result: \(surveyOptionID)")
        }
    }
}

#endif

private extension SamplePaywallsList {

    enum Display {

        case template(PaywallTemplate, PaywallViewMode)
        case customFont(PaywallTemplate)
        @available(watchOS, unavailable)
        case customPaywall(PaywallViewMode)
        case missingPaywall
        case unrecognizedPaywall
        case customerCenter
        #if PAYWALL_COMPONENTS
        case componentPaywall(PaywallComponentsData)
        #endif

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

        case .customerCenter:
            return "customer-center"
        #if PAYWALL_COMPONENTS
        case .componentPaywall:
            return "component-paywall"
        #endif
        }
    }

}

extension PaywallTemplate {

    var name: String {
        switch self {
        case .template1:
            return "1: Minimalist"
        case .template2:
            return "2: Bold packages"
        case .template3:
            return "3: Feature list"
        case .template4:
            return "4: Horizontal packages"
        case .template5:
            return "5: Minimalist with Small Banner"
        case .template7:
            return "7: Multi-tier with Small Banner"
        }
    }

}


struct SamplePaywallsList_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SamplePaywallsList()
        }
    }
}

