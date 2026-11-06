//
//  open-workflow-uikit.swift
//  Maestro
//
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import RevenueCat
import RevenueCatUI
import SwiftUI
import UIKit

extension E2ETestFlowView {
    /// Opens the workflow paywall through the UIKit `PaywallViewController`, with a
    /// `dismissRequestedHandler` written the way host apps commonly write one: it dismisses the
    /// controller the host itself presented and ignores the controller it is handed.
    ///
    /// That shape matters. The SDK presents the exit offer in a controller the host never created, so
    /// forwarding dismissal to this handler used to leave the exit offer stranded on screen. Keep the
    /// handler as it is: switching it to `controller.dismiss(animated:)` makes the flow pass no matter
    /// what the SDK does, and stops guarding anything.
    struct OpenWorkflowUIKit: View {

        static let offeringIdentifier = "default_workflows"

        enum GetOfferingsState {
            case loading
            case loaded(Offering)
            case failed(Error)
        }

        @State private var offeringsState: GetOfferingsState = .loading

        var body: some View {
            VStack {
                Text("Workflow paywall (UIKit)")
                    .font(.largeTitle)

                switch offeringsState {
                case .loading:
                    Text("Loading offerings...")
                case .loaded(let offering):
                    Button("Present Paywall") {
                        Self.presentPaywall(for: offering)
                    }
                    .buttonStyle(.borderedProminent)
                case .failed(let error):
                    Text("Error: \(error.localizedDescription)")
                        .foregroundColor(.red)
                }

                EntitlementView(identifier: "pro")
            }
            .task {
                do {
                    let offerings = try await Purchases.shared.offerings()
                    if let offering = offerings.offering(identifier: Self.offeringIdentifier) {
                        offeringsState = .loaded(offering)
                    } else {
                        offeringsState = .failed(OfferingError.notFound)
                    }
                } catch {
                    offeringsState = .failed(error)
                }
            }
            .multilineTextAlignment(.center)
        }

        @MainActor
        private static func presentPaywall(for offering: Offering) {
            guard let presenter = Self.topViewController() else { return }

            var paywall: PaywallViewController?
            paywall = PaywallViewController(
                offering: offering,
                fonts: DefaultPaywallFontProvider(),
                displayCloseButton: true,
                dismissRequestedHandler: { _ in
                    // Deliberately ignores the controller it is handed. See the type doc.
                    paywall?.dismiss(animated: true)
                }
            )

            guard let paywall else { return }
            presenter.present(paywall, animated: true)
        }

        @MainActor
        private static func topViewController() -> UIViewController? {
            let windows = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)

            guard var top = (windows.first(where: \.isKeyWindow) ?? windows.first)?.rootViewController else {
                return nil
            }

            while let presented = top.presentedViewController {
                top = presented
            }

            return top
        }

        enum OfferingError: LocalizedError {
            case notFound

            var errorDescription: String? {
                switch self {
                case .notFound:
                    return "Offering '\(OpenWorkflowUIKit.offeringIdentifier)' not found"
                }
            }
        }
    }
}
