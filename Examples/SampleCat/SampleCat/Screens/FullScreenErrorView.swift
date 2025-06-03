import RevenueCat
import SwiftUI

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
        VStack {
            ScrollView {
                ConceptIntroductionView(
                    imageName: "visual-error",
                    title: title,
                    description: error.localizedDescription
                )
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)

            Spacer()

            Button(action: {
                Task {
                    await healthViewModel.fetchHealthReport()
                }
            }, label: {
                Text(healthViewModel.isfetchingHealthReport ? "Retrying..." : "Try again")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            })
            .padding(.horizontal)
            .buttonStyle(.borderedProminent)
            .tint(.accent)
        }
        .background(.red.opacity(0.1))
        .animation(.default, value: healthViewModel.isfetchingHealthReport)
        .frame(maxWidth: .infinity)
        .scrollContentBackground(.hidden)
        .safeAreaPadding()
        .background {
            ContentBackgroundView(color: .accent)
        }
    }
}
