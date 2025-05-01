import SwiftUI
import RevenueCat

struct FullScreenErrorView: View {
    @Environment(HealthViewModel.self) var healthViewModel
    let error: PurchasesDiagnostics.SDKHealthError

    var title: String {
        switch error {
        case .invalidAPIKey:
            return "Invalid API Key"
        case .noOfferings:
            return "No Offerings"
        case .offeringConfiguration:
            return "Invalid Configuration for Current Offering"
        case .invalidBundleId:
            return "Invalid Bundle ID"
        case .invalidProducts:
            return "No Valid Products Found"
        case .notAuthorizedToMakePayments:
            return "Can't Make Payments"
        case .unknown:
            return "Unexpected Error"
        }
    }

    var body: some View {
        ScrollView {
            ConceptIntroductionView(imageName: "visual-products",
                                    title: title,
                                    description: error.localizedDescription)

            Button(action: {
                Task {
                    await healthViewModel.fetchHealthReport()
                }
            }, label: {
                if healthViewModel.isfetchingHealthReport {
                    Text("Retrying...")
                } else {
                    Text("Try Again")
                }
            })
            .buttonStyle(.borderedProminent)
            .tint(.accent)
        }
        .frame(maxWidth: .infinity)
        .scrollContentBackground(.hidden)
        .background {
            ContentBackgroundView(color: .accent)
        }
    }
}
