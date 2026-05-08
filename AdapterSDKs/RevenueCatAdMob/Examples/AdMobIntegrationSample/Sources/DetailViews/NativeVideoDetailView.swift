import SwiftUI

struct NativeVideoDetailView: View {

    @ObservedObject var manager: NativeVideoAdManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Integrated native video ad. Native video test IDs can be unreliable in test environments.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Button("Load") { self.manager.loadAd() }
                    .buttonStyle(.bordered)
                    .disabled(Messages.isLoading(self.manager.message))

                if let message = self.manager.message {
                    ResultCard(message: message)
                }

                if let nativeAd = self.manager.nativeAd {
                    NativeAdViewRepresentable(nativeAd: nativeAd)
                        .frame(height: 300)
                        .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Native Video Ad")
        .navigationBarTitleDisplayMode(.inline)
    }

}
