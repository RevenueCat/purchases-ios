import RevenueCat
import RevenueCatUI
import SwiftUI
import StoreKit

public struct ContentView: View {
    @State private var presentCustomerCenter = false

    public init() {}

    public var body: some View {
        VStack {
            Button("Present Customer Center") {
                presentCustomerCenter = true
            }
        }
        .presentCustomerCenter(isPresented: $presentCustomerCenter)
        .onAppear {
            Task {
                do {
                    for await result in Transaction.currentEntitlements {
                        switch result {
                        case .verified(let transaction):
                            print("✅ Verified active transaction for \(transaction.productID)")
                        case .unverified(_, let error):
                            print("⚠️ Unverified transaction: \(error)")
                        }
                    }
                } catch {
                    print("❌ Failed to fetch entitlements: \(error)")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
