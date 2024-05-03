//
//  SupportView.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

import SwiftUI
import RevenueCat

@available(iOS 15.0, *)
public struct SupportView: View {

    public init() { }

    @State private var hasSubscriptions: Bool = false

    public var body: some View {
        NavigationView {
            NavigationLink(destination: destinationView()) {
                Text("Billing and subscription help")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
            .task {
                await loadHasSubscriptions()
            }
    }

    private func loadHasSubscriptions() async {
        Task {
            self.hasSubscriptions = try await Purchases.shared.customerInfo().activeSubscriptions.count > 0
        }
    }

    @ViewBuilder
    private func destinationView() -> some View {
        if self.hasSubscriptions {
            ManageSubscriptionsView()
        } else {
            NoSubscriptionsView()
        }
    }

}



@available(iOS 15.0.0, *)
#Preview {
    SupportView()
}
