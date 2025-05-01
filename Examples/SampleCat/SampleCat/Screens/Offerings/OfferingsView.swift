import SwiftUI
import RevenueCat

struct OfferingsView: View {
    @Environment(UserViewModel.self) private var userViewModel
    @State private var selectedOffering: OfferingViewModel?
    @State private var offerings = [OfferingViewModel]()
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                ConceptIntroductionView(imageName: "visual-offerings",
                                        title: "Offerings",
                                        description: "Offerings are the products you can “offer” to customers on your paywall.")

                VStack {
                    ForEach(offerings) { offering in
                        NavigationLink(destination: { OfferingPackagesView(offering: offering) }) {
                            OfferingCell(offering: offering)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
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
                status: offering.status,
                products: offering.packages.map { package in
                    ProductViewModel(
                        id: package.identifier,
                        status: package.status,
                        title: package.productIdentifier,
                        description: package.description,
                        storeProduct: nil
                    )
                }
            )
        }
        self.selectedOffering = offerings.first
    }
}
