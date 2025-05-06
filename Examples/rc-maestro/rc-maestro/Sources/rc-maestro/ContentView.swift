import RevenueCat
import RevenueCatUI
import SwiftUI
import StoreKit

public struct ContentView: View {
    @State private var presentCustomerCenter = false
    @State private var manageSubscriptions = false
    @State private var actionSheetIsPresented = false

    @State private var productToBuy: String?

    public init() { }

    public var body: some View {
        VStack {
            Spacer()
            Button("Present Customer Center") {
                presentCustomerCenter = true
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .ignoresSafeArea(.all)
        .presentCustomerCenter(isPresented: $presentCustomerCenter)
        .manageSubscriptionsSheet(isPresented: $manageSubscriptions)
        .confirmationDialog(
            "Buy something",
            isPresented: $actionSheetIsPresented
        ) {
            buttonsView
        }
        .safeAreaInset(edge: .bottom, content: {
            HStack {
                Button("Buy something") {
                    actionSheetIsPresented = true
                }
                .buttonStyle(.bordered)

                Button("Manage subscriptions") {
                    manageSubscriptions = true
                }
                .buttonStyle(.bordered)
            }
        })
    }

    @ViewBuilder
    var buttonsView: some View {
        ForEach(Self.products, id: \.self) { product in
            Button {
                productToBuy = product

                Task {
                    let fetchedProducts = await Purchases.shared.products([product])
                    guard let product = fetchedProducts.first else {
                        print("⚠️ Failed to find product: \(product)")
                        await MainActor.run {
                            productToBuy = nil
                        }
                        return
                    }

                    do {
                        _ = try await Purchases.shared.purchase(product: product)
                    } catch {
                        print("⚠️ Purchase failed: \(error)")
                    }

                    await MainActor.run {
                        productToBuy = nil
                    }
                }
            } label: {
                Text("Buy \(product)")
            }
        }
    }

    static var products: [String] {
         [
             "maestro.weekly.tests.01",
             "maestro.monthly.tests.02",
             "maestro.weekly2.tests.01"
         ]
     }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
