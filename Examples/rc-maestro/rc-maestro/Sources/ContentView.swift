import RevenueCat
import RevenueCatUI
import SwiftUI
import StoreKit

public struct ContentView: View {
    @State private var presentCustomerCenter = false
    @State private var purchasing = false

    public init() {}

    public var body: some View {
        VStack {
            Button {
                purchasing = true
                Task {
                    let product = await Purchases.shared.products(["maestro.weekly.tests"]).first!
                    _ = try await Purchases.shared.purchase(product: product)
                    
                    Task { @MainActor in
                        purchasing = false
                    }
                }
            } label: {
                if purchasing {
                    ProgressView()
                } else {
                   Text("Buy product")
                }
            }
            .buttonStyle(.bordered)
            .padding(.bottom, 16)

            Button("Present Customer Center") {
                presentCustomerCenter = true
            }
            .buttonStyle(.borderedProminent)
        }
        .presentCustomerCenter(isPresented: $presentCustomerCenter)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
