//
//  PresentPaywallIfNeededView.swift
//  RCTTester
//

import SwiftUI
import RevenueCat
import RevenueCatUI

/// A screen that demonstrates the `.presentPaywallIfNeeded` view modifier.
///
/// This screen is pushed via navigation and immediately applies the modifier,
/// which checks the user's entitlements and presents the paywall if the specified
/// entitlement is not active. If the entitlement is already active, the paywall
/// won't appear -- this is the expected behavior of the API.
struct PresentPaywallIfNeededView: View {

    let offering: Offering
    let myAppPurchaseLogic: MyAppPurchaseLogic?

    private let requiredEntitlementIdentifier = "pro"

    /// Tracks whether the paywall was already presented once during this screen's lifetime.
    /// This prevents the modifier from re-triggering the paywall when the user dismisses it
    /// without purchasing and then interacts with the navigation (e.g. tapping back).
    @State private var paywallAlreadyPresented = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.on.rectangle")
                .font(.largeTitle)
                .foregroundColor(.accentColor)

            Text(".presentPaywallIfNeeded")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "Offering", value: offering.identifier)
                InfoRow(label: "Entitlement", value: "\"\(requiredEntitlementIdentifier)\"")
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            Text("The `.presentPaywallIfNeeded` modifier checks whether the entitlement "
                 + "\"\(requiredEntitlementIdentifier)\" is active. If it is not, "
                 + "the paywall for offering \"\(offering.identifier)\" is presented automatically.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("If no paywall appeared, the entitlement is already active.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle(".presentPaywallIfNeeded")
        .navigationBarTitleDisplayMode(.inline)
        .presentPaywallIfNeeded(
            offering: offering,
            myAppPurchaseLogic: myAppPurchaseLogic,
            shouldDisplay: { customerInfo in
                guard !paywallAlreadyPresented else { return false }
                let hasEntitlement = customerInfo.entitlements[requiredEntitlementIdentifier]?.isActive == true
                return !hasEntitlement
            },
            onDismiss: {
                print(".presentPaywallIfNeeded dismissed")
                paywallAlreadyPresented = true
            }
        )
    }
}

private struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .font(.system(.body, design: .monospaced))
        }
    }
}
