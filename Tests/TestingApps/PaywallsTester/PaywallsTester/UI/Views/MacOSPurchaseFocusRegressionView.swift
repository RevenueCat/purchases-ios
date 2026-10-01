//
//  MacOSPurchaseFocusRegressionView.swift
//  PaywallsTester
//

#if os(macOS) && DEBUG

import AppKit
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
    private static let hostAccountFieldAccessibilityID = "focus-account-field"

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

    @State
    private var didConfirmHostFieldFocus = false

    @FocusState
    private var focusedField: FocusedField?

    private let offering: Offering

    init() {
        let loader = SamplePaywallLoader()
        self.offering = loader.offering(with: Self.paywallComponents)
        self._purchaseHandler = .init(wrappedValue: PurchaseHandler.mock().with(delay: 60))
    }

    var body: some View {
        HSplitView {
            Form {
                Section("Focus-heavy host controls") {
                    TextField("Account name", text: self.$accountName)
                        .focused(self.$focusedField, equals: .account)
                        .accessibilityIdentifier(Self.hostAccountFieldAccessibilityID)
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
            // The first ping is readiness: only ack once an AppKit text field is first responder.
            // Later pings are liveness checks after purchase starts (focus will already be resigned).
            if !self.didConfirmHostFieldFocus {
                guard self.ensureHostTextFieldIsFirstResponder() else { return }
                self.didConfirmHostFieldFocus = true
            }

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

            // Re-check AppKit first responder here — the earlier ping only proves focus at
            // launch, and `didConfirmHostFieldFocus` would otherwise let this proceed stale.
            guard self.ensureHostTextFieldIsFirstResponder() else { return }

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

    @discardableResult
    private func ensureHostTextFieldIsFirstResponder() -> Bool {
        self.focusedField = .account

        guard let window = Self.keyWindow() else {
            return false
        }

        if Self.isTextInput(window.firstResponder) {
            return true
        }

        let field = Self.hostAccountField(in: window.contentView) ?? Self.firstTextInput(in: window.contentView)
        guard let field, window.makeFirstResponder(field) else {
            return false
        }

        return Self.isTextInput(window.firstResponder)
    }

    private static func keyWindow() -> NSWindow? {
        NSApplication.shared.keyWindow
            ?? NSApplication.shared.mainWindow
            ?? NSApplication.shared.windows.first(where: \.isVisible)
    }

    private static func isTextInput(_ responder: NSResponder?) -> Bool {
        responder is NSTextField || responder is NSTextView || responder is NSText
    }

    private static func hostAccountField(in view: NSView?) -> NSView? {
        guard let view else { return nil }

        if Self.matchesHostAccountField(view) {
            if Self.isTextInput(view) {
                return view
            }
            return Self.firstTextInput(in: view)
        }

        for subview in view.subviews {
            if let found = Self.hostAccountField(in: subview) {
                return found
            }
        }
        return nil
    }

    private static func matchesHostAccountField(_ view: NSView) -> Bool {
        view.identifier?.rawValue == Self.hostAccountFieldAccessibilityID
            || view.accessibilityIdentifier() == Self.hostAccountFieldAccessibilityID
    }

    private static func firstTextInput(in view: NSView?) -> NSView? {
        guard let view else { return nil }

        if Self.isTextInput(view) {
            return view
        }

        for subview in view.subviews {
            if let found = Self.firstTextInput(in: subview) {
                return found
            }
        }
        return nil
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
