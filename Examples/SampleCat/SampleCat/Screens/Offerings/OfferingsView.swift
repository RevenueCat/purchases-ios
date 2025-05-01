import SwiftUI
import RevenueCat

struct OfferingsView: View {
    @Environment(UserViewModel.self) private var userViewModel
    @State private var selectedOffering: OfferingViewModel?
    @State private var offerings = [OfferingViewModel]()
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            ConceptIntroductionView(imageName: "visual-offerings",
                                    title: "Offerings",
                                    description: "Offerings are the products you can “offer” to customers on your paywall.")

            VStack {
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
            .overlay {
                if isLoading {
                    Spinner()
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background {
            ContentBackgroundView(color: Color("RC-green"))
        }
        .onAppear(perform: loadData)
        .refreshable(action: loadData)
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
        print(report)
        print(report.offerings)
        self.offerings = report.offerings.map { offering in
            OfferingViewModel(
                identifier: offering.identifier,
                status: offering.status
            )
        }
        self.selectedOffering = offerings.first
    }
}
