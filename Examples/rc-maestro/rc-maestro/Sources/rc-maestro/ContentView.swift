import RevenueCat
import RevenueCatUI
import SwiftUI
import StoreKit

public struct ContentView: View {
    @State private var presentCustomerCenter = false
    @State private var manageSubscriptions = false
    @State private var actionSheetIsPresented = false

    @State private var productToBuy: String?

    public init() {}

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
        .confirmationDialog(
            "Buy something",
            isPresented: $actionSheetIsPresented
        ) {
            buttonsView
        }
        .manageSubscriptionsSheet(isPresented: $manageSubscriptions)
    }

    @ViewBuilder
    var buttonsView: some View {
        ForEach(Self.products, id: \.self) { product in
            Button {
                productToBuy = product

                Task {
                    let product = await Purchases.shared.products([product]).first!
                    _ = try await Purchases.shared.purchase(product: product)

                    Task { @MainActor in
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
            "maestro.weekly.tests",
            "maestro.monthly.tests"
        ]
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
