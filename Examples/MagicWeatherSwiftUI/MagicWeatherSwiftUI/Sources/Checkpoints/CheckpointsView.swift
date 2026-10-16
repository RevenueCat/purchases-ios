//
//  CheckpointsView.swift
//  Magic Weather SwiftUI
//

// The checkpoints API is invite-only and experimental, so it needs this SPI import.
@_spi(InviteOnlyCheckpointsApi) import RevenueCatUI
import SwiftUI

/*
 Samples that show how an app reacts to a checkpoint result.
 Each sample fires a checkpoint that you configure in the RevenueCat dashboard. See the README.
 */

struct CheckpointsView: View {

    var body: some View {
        List {
            NavigationLink(destination: HardPaywallSampleView()) {
                SampleLabel(
                    title: "Hard paywall",
                    subtitle: "The content stays locked until the result has an active entitlement.",
                    systemImage: "lock.fill"
                )
            }
            NavigationLink(destination: SoftPaywallSampleView()) {
                SampleLabel(
                    title: "Soft paywall",
                    subtitle: "The content is always available. The result only updates the status.",
                    systemImage: "rectangle.portrait.and.arrow.right"
                )
            }
            NavigationLink(destination: OnboardingSampleView()) {
                SampleLabel(
                    title: "Onboarding",
                    subtitle: "Fires a checkpoint at the last step and always completes.",
                    systemImage: "sparkles"
                )
            }
            NavigationLink(destination: EntitlementGateSampleView()) {
                SampleLabel(
                    title: "Entitlement gate",
                    subtitle: "Checks CustomerInfo first and skips the checkpoint for subscribers.",
                    systemImage: "person.badge.key.fill"
                )
            }
        }
    }

}

private struct SampleLabel: View {

    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 3) {
                Text(self.title)
                    .font(.headline)
                Text(self.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: self.systemImage)
                .frame(width: 28)
        }
    }

}

extension FlowResult {

    /// The identifiers of the entitlements that the flow made active, sorted.
    var obtainedEntitlementIdentifiers: [String] {
        return self.obtainedEntitlements.map(\.entitlementInfo.identifier).sorted()
    }

}
