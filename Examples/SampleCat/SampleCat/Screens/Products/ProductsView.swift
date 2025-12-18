import RevenueCat
import SwiftUI

struct ProductsView: View {
    @Environment(UserViewModel.self) private var userViewModel
    @Environment(HealthViewModel.self) private var healthViewModel

    @State private var presentedProduct: ProductViewModel?

    var body: some View {
        ScrollView {
            ConceptIntroductionView(imageName: "visual-products",
                                    title: "Products",
                                    description: "Products are the individual in-app purchases and subscriptions you set up on the App Store.")
            VStack {
                ForEach(healthViewModel.products) { product in
                    PurchasableCell(viewModel: product)
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
            ContentBackgroundView(color: .accent)
        }
        .sheet(item: $presentedProduct, content: { product in
            Text(product.title ?? product.id)
        })
        .task {
            guard !healthViewModel.isfetchingHealthReport, healthViewModel.products.isEmpty else { return }

            await healthViewModel.fetchHealthReport()
        }
        .refreshable(action: healthViewModel.fetchHealthReport)
    }
}
