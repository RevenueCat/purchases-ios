import SwiftUI
import RevenueCat

struct OfferingsView: View {
    @Environment(UserViewModel.self) private var userViewModel
    @State private var selectedOffering: OfferingViewModel?
    @State private var offerings = [OfferingViewModel]()
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(offerings) { offering in
                            Button(action: { selectedOffering = offering }) {
                                Text(offering.identifier)
                                    .textCase(.uppercase)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 16)
                                    .background(selectedOffering == offering ? Color.accentColor : .secondary.opacity(0.2))
                                    .foregroundStyle(selectedOffering == offering ? Color.white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear(perform: loadData)
            .refreshable(action: loadData)
            .navigationTitle("Offerings")
        }
    }
    
    private func loadData() {
        Task {
            isLoading = true
            await userViewModel.fetchOfferings()
            do {
                try await checkAppHealth()
            } catch let error {
                print(error)
            }
            isLoading = false
        }
    }
    
    private func checkAppHealth() async throws {
        let report = await PurchasesDiagnostics.default.healthReport()
        self.offerings = report.offerings.map { offering in
            OfferingViewModel(
                identifier: offering.identifier,
                status: offering.status
            )
        }
        self.selectedOffering = offerings.first
    }
}
