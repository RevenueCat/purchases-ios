//
//  PresentPaywallIfNeededView.swift
//  RCTTester
//

import SwiftUI
import RevenueCat
import RevenueCatUI

/// A screen that demonstrates the `.presentPaywallIfNeeded` view modifier.
///
/// Presented as a sheet, this view immediately applies the modifier on appear.
/// The SDK checks whether the specified entitlement is active and presents the
/// paywall if it is not. If the entitlement is already active, the paywall
/// shouldn't appear, as this is the expected behavior of the API.
struct PresentPaywallIfNeededView: View {

    let offering: Offering
    let entitlementIdentifier: String
    let myAppPurchaseLogic: MyAppPurchaseLogic?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.on.rectangle")
                .font(.largeTitle)
                .foregroundColor(.accentColor)

            Text(".presentPaywallIfNeeded")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                InfoRow(label: "Offering", value: offering.identifier)
                InfoRow(label: "Entitlement", value: "\"\(entitlementIdentifier)\"")
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            Text("The `.presentPaywallIfNeeded` modifier checks whether the entitlement "
                 + "\"\(entitlementIdentifier)\" is active. If it is not, "
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
            requiredEntitlementIdentifier: entitlementIdentifier,
            offering: offering,
            myAppPurchaseLogic: myAppPurchaseLogic,
            onDismiss: {
                print(".presentPaywallIfNeeded dismissed")
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
