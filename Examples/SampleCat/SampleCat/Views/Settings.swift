import SwiftUI
import RevenueCatUI

struct Settings: View {
    @State private var showCustomerCenter = false
    
    var body: some View {
        VStack {
            Button(action: { showCustomerCenter = true }) {
                Text("Show Customer Center")
            }
        }
        .sheet(isPresented: $showCustomerCenter) {
            CustomerCenterView()
        }
    }
}
