import RevenueCat
import SwiftUI

struct OfferingsView: View {
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(HealthViewModel.self) private var healthViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                ConceptIntroductionView(imageName: "visual-offerings",
                                        title: "Offerings",
                                        description: "Offerings are the products you can “offer” to customers on your paywall.")

                VStack {
                    ForEach(healthViewModel.offerings) { offering in
                        NavigationLink(destination: { OfferingPackagesView(offering: offering) }) {
                            OfferingCell(offering: offering)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .blur(radius: healthViewModel.isfetchingHealthReport ? 5 : 0)
                .overlay {
                    if healthViewModel.isfetchingHealthReport {
                        Spinner()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background {
                ContentBackgroundView(color: Color("RC-green"))
            }
            .task {
                guard !healthViewModel.isfetchingHealthReport, healthViewModel.offerings.isEmpty else { return }

                await healthViewModel.fetchHealthReport()
            }
            .refreshable(action: healthViewModel.fetchHealthReport)
        }
    }
}
