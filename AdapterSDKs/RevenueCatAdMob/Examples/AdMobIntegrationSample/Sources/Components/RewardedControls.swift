import SwiftUI

/// Reward-verification toggle plus Load/Show buttons and a `ResultCard` for
/// surfacing reward outcomes. Used by both rewarded and rewarded-interstitial.
struct RewardedControls: View {

    let message: Message?
    let canShow: Bool
    @Binding var usesRewardVerification: Bool
    let onLoad: () -> Void
    let onShow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            self.verificationToggle
                .disabled(Message.isLoading(self.message))

            Button("Load") { self.onLoad() }
                .buttonStyle(.bordered)
                .disabled(Message.isLoading(self.message))

            Button("Show") { self.onShow() }
                .buttonStyle(.borderedProminent)
                .disabled(!self.canShow)

            if let message = self.message {
                ResultCard(message: message)
            }
        }
    }

    private var verificationToggle: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Toggle("", isOn: self.$usesRewardVerification)
                    .labelsHidden()
                    .tint(.green)
                    .fixedSize()

                Text("Reward Verification")
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            Text("Applies to the next loaded ad")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(uiColor: .separator).opacity(0.45), lineWidth: 1)
        )
    }

}
