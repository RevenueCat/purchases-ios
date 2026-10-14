import SwiftUI

struct HomeView: View {

    @StateObject private var manager = InterstitialAdManager()

    var body: some View {
        NavigationView {
            Form {
                Section("Configuration") {
                    self.field("API key", text: self.$manager.apiKey)
                    self.field("Server URL", text: self.$manager.serverURL)
                    self.field("Placement ID", text: self.$manager.placementID)
                }

                Section("Interstitial") {
                    Button("Load & Show") { self.manager.loadAndShowAd() }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .disabled(self.manager.isLoading || self.manager.isPresenting)

                    HStack {
                        Button("Load") { self.manager.loadAd() }
                            .buttonStyle(.bordered)
                            .disabled(self.manager.isLoading)

                        Button("Show") { self.manager.showAd() }
                            .buttonStyle(.bordered)
                            .disabled(!self.manager.canShow || self.manager.isPresenting)
                    }
                }

                Section("Events") {
                    if self.manager.log.isEmpty {
                        Text("No events yet")
                            .foregroundColor(.secondary)
                    }
                    ForEach(Array(self.manager.log.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.caption.monospaced())
                    }
                }
            }
            .navigationTitle("RevenueCat Ads")
        }
        .navigationViewStyle(.stack)
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField(title, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }

}
