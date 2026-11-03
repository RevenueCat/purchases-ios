import RevenueCat
import SwiftUI

struct CheckpointsTabView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    Text("Checkpoints")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                    Text("Fire a checkpoint at a point in your app, and let the dashboard decide which flow the customer sees.")
                    Text("Checkpoints are in private beta. Contact RevenueCat to get access.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.vertical, 32)

                VStack(spacing: 12) {
                    NavigationLink {
                        HardPaywallView()
                    } label: {
                        SampleCell(title: "Hard paywall",
                                   subtitle: "The content stays locked until the customer has access.")
                    }
                    NavigationLink {
                        SoftPaywallView()
                    } label: {
                        SampleCell(title: "Soft paywall",
                                   subtitle: "The content is always available. The result only updates the status.")
                    }
                    NavigationLink {
                        OnboardingView()
                    } label: {
                        SampleCell(title: "Onboarding",
                                   subtitle: "Fires a checkpoint at the last step and always completes.")
                    }
                    NavigationLink {
                        EntitlementGateView()
                    } label: {
                        SampleCell(title: "Entitlement gate",
                                   subtitle: "Checks CustomerInfo first and skips the checkpoint for subscribers.")
                    }
                }
                .buttonStyle(.plain)
                .padding()
            }
            .scrollContentBackground(.hidden)
            .background {
                ContentBackgroundView(color: Color("RC-green"))
            }
        }
    }
}

private struct SampleCell: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(scheme == .dark ? Color.black : Color.white)
        .foregroundStyle(Color.primary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension CustomerInfo {
    /* Whether the customer has access to premium content. Uses `Constants.entitlementIdentifier` when it is set. */
    var hasPremiumAccess: Bool {
        guard let entitlementIdentifier = Constants.entitlementIdentifier else {
            return !entitlements.active.isEmpty
        }
        return entitlements[entitlementIdentifier]?.isActive == true
    }
}
