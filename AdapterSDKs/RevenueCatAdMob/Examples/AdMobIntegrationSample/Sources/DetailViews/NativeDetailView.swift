import SwiftUI

struct NativeDetailView: View {

    @ObservedObject var manager: NativeAdManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Integrated native ad. Native test IDs can be unreliable; custom IDs are best for validation.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Status: \(self.manager.message)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Button("Load") { self.manager.loadAd() }
                    .buttonStyle(.bordered)
                    .disabled(Messages.isLoading(self.manager.message))

                if let nativeAd = self.manager.nativeAd {
                    NativeAdViewRepresentable(nativeAd: nativeAd)
                        .frame(height: 300)
                        .padding(.top, 8)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Native Ad")
        .navigationBarTitleDisplayMode(.inline)
    }

}
