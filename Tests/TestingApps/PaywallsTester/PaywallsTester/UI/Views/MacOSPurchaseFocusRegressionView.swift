//
//  MacOSPurchaseFocusRegressionView.swift
//  PaywallsTester
//

#if os(macOS) && DEBUG

import SwiftUI
@_spi(Internal) import RevenueCat
@_spi(Internal) @testable import RevenueCatUI

@available(macOS 12.0, *)
struct MacOSPurchaseFocusRegressionView: View {

    private static let responsivenessPing = Notification.Name(
        "com.revenuecat.PaywallsTester.purchaseFocusRegression.ping"
    )
    private static let responsivenessAcknowledgement = Notification.Name(
        "com.revenuecat.PaywallsTester.purchaseFocusRegression.acknowledgement"
    )
    private static let startPurchase = Notification.Name(
        "com.revenuecat.PaywallsTester.purchaseFocusRegression.startPurchase"
    )
    private static let purchaseStarted = Notification.Name(
        "com.revenuecat.PaywallsTester.purchaseFocusRegression.purchaseStarted"
    )

    private enum FocusedField {
        case account
        case email
        case notes
    }

    @StateObject
    private var purchaseHandler: PurchaseHandler

    @State
    private var accountName = "Focused account"

    @State
    private var email = "focused@example.com"

    @State
    private var notes = "Keep this field active before purchasing."

    @State
    private var responsivenessCount = 0

    @State
    private var showResponsivenessAlert = false

    @State
    private var pendingPurchaseRunID: String?

    @FocusState
    private var focusedField: FocusedField?

    private let offering: Offering
    private let customerInfo: CustomerInfo

    init() {
        let loader = SamplePaywallLoader()
        self.offering = loader.offering(with: Self.paywallComponents)
        self.customerInfo = loader.customerInfo
        self._purchaseHandler = .init(wrappedValue: PurchaseHandler.mock().with(delay: 60))
    }

    var body: some View {
        HSplitView {
            Form {
                Section("Focus-heavy host controls") {
                    TextField("Account name", text: self.$accountName)
                        .focused(self.$focusedField, equals: .account)
                        .accessibilityIdentifier("focus-account-field")
                    TextField("Email", text: self.$email)
                        .focused(self.$focusedField, equals: .email)
                    TextEditor(text: self.$notes)
                        .focused(self.$focusedField, equals: .notes)
                        .frame(minHeight: 80)
                    Toggle("Send purchase receipt", isOn: .constant(true))
                }

                Section("Responsiveness assertion") {
                    Button("Host remains responsive") {
                        self.confirmResponsiveness()
                    }
                    .accessibilityIdentifier("host-responsiveness-button")
                    .keyboardShortcut("r", modifiers: .command)

                    Text("Responses: \(self.responsivenessCount)")
                        .accessibilityIdentifier("host-responsiveness-count")
                    Text("Purchase state: \(self.purchaseHandler.actionInProgress ? "disabled" : "ready")")
                        .accessibilityIdentifier("purchase-action-state")
                }
            }
            .frame(minWidth: 320)

            PaywallView(configuration: .init(
                offering: self.offering,
                customerInfo: self.customerInfo,
                displayCloseButton: false,
                introEligibility: .producing(eligibility: .ineligible),
                purchaseHandler: self.purchaseHandler
            ))
            .frame(minWidth: 420)
        }
        .frame(minWidth: 800, minHeight: 620)
        .onAppear {
            self.focusedField = .account
        }
        .alert("Host remains responsive", isPresented: self.$showResponsivenessAlert) {
            Button("OK", role: .cancel) {}
        }
        .onReceive(
            DistributedNotificationCenter.default().publisher(for: Self.responsivenessPing)
        ) { notification in
            self.responsivenessCount += 1
            DistributedNotificationCenter.default().postNotificationName(
                Self.responsivenessAcknowledgement,
                object: notification.object as? String,
                userInfo: nil,
                deliverImmediately: true
            )
        }
        .onReceive(
            DistributedNotificationCenter.default().publisher(for: Self.startPurchase)
        ) { notification in
            guard let package = self.offering.availablePackages.first(where: { $0.packageType == .annual }) else {
                return
            }

            self.pendingPurchaseRunID = notification.object as? String
            Task {
                try? await self.purchaseHandler.purchase(package: package)
            }
        }
        .onChange(of: self.purchaseHandler.actionInProgress) { actionInProgress in
            guard actionInProgress, let runID = self.pendingPurchaseRunID else { return }
            self.pendingPurchaseRunID = nil
            DistributedNotificationCenter.default().postNotificationName(
                Self.purchaseStarted,
                object: runID,
                userInfo: nil,
                deliverImmediately: true
            )
        }
    }

    private func confirmResponsiveness() {
        self.responsivenessCount += 1
        self.showResponsivenessAlert = true
    }

    private static let paywallComponents: PaywallComponentsData = .init(
        templateName: "macos-purchase-focus-regression",
        assetBaseURL: URL(string: "https://assets.revenuecat.com")!,
        componentsConfig: .init(base: .init(
            stack: .init(
                components: [
                    .text(.init(
                        text: "title",
                        fontWeight: .bold,
                        color: .init(light: .hex("#111111")),
                        fontSize: 28,
                        horizontalAlignment: .center
                    )),
                    .package(.init(
                        packageID: PackageType.annual.identifier,
                        isSelectedByDefault: true,
                        applePromoOfferProductCode: nil,
                        stack: .init(components: [
                            .text(.init(
                                text: "package",
                                color: .init(light: .hex("#111111")),
                                padding: .init(top: 16, bottom: 16, leading: 16, trailing: 16)
                            ))
                        ])
                    )),
                    .purchaseButton(.init(
                        stack: .init(
                            components: [
                                .text(.init(
                                    text: "cta",
                                    fontWeight: .bold,
                                    color: .init(light: .hex("#ffffff")),
                                    backgroundColor: .init(light: .hex("#3d6787")),
                                    padding: .init(top: 14, bottom: 14, leading: 24, trailing: 24)
                                ))
                            ],
                            shape: .pill
                        ),
                        action: .inAppCheckout,
                        method: .inAppCheckout,
                        name: nil
                    ))
                ],
                dimension: .vertical(.center, .center),
                size: .init(width: .fill, height: .fill),
                spacing: 24,
                padding: .init(top: 32, bottom: 32, leading: 32, trailing: 32)
            ),
            stickyFooter: nil,
            background: .color(.init(light: .hex("#ffffff")))
        )),
        componentsLocalizations: [
            "en_US": [
                "title": .string("macOS focus regression"),
                "package": .string("Annual plan"),
                "cta": .string("Start suspended purchase")
            ]
        ],
        revision: 1,
        defaultLocaleIdentifier: "en_US"
    )

}

#endif
