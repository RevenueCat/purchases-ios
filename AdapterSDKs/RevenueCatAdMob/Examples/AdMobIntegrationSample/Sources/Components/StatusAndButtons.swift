import SwiftUI

/// Status text + Load/Show buttons used by simple full-screen ad formats
/// (interstitial, app open).
struct StatusAndButtons: View {

    let message: String?
    let canShow: Bool
    let onLoad: () -> Void
    let onShow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button("Load") { self.onLoad() }
                    .buttonStyle(.bordered)
                    .disabled(Messages.isLoading(self.message))

                Button("Show") { self.onShow() }
                    .buttonStyle(.borderedProminent)
                    .disabled(!self.canShow)
            }

            if let message = self.message {
                ResultCard(message: message)
            }
        }
    }

}
