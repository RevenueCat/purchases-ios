import RevenueCat
import SwiftUI

struct OfferingPackagesView: View {
    @State var offering: OfferingViewModel

    var body: some View {
        ScrollView {
            ConceptIntroductionView(imageName: "visual-offerings",
                                    title: "Packages",
                                    description: "Packages are a representation of the products that you “offer” to customers on your paywall.")

            VStack {
                ForEach(offering.packages) { package in
                    PurchasableCell(viewModel: package)
                }
            }
            .padding()
        }
        .scrollContentBackground(.hidden)
        .background {
            ContentBackgroundView(color: Color("RC-green"))
        }
    }
}
