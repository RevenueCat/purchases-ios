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
    @State private var areSubscriptionsFromApple: Bool = false

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
            let customerInfo = try await Purchases.shared.customerInfo()
            self.hasSubscriptions = customerInfo.activeSubscriptions.count > 0
            guard let firstActiveEntitlement: EntitlementInfo = customerInfo.entitlements.active.first?.value else {
                self.areSubscriptionsFromApple = false
                return
            }

            self.areSubscriptionsFromApple = firstActiveEntitlement.store == .appStore || firstActiveEntitlement.store == .macAppStore
        }
    }

    @ViewBuilder
    private func destinationView() -> some View {
        if self.hasSubscriptions {
            if areSubscriptionsFromApple {
                ManageSubscriptionsView()
            } else {
                WrongPlatformView()
            }
        } else {
            NoSubscriptionsView()
        }
    }

}



@available(iOS 15.0.0, *)
#Preview {
    SupportView()
}
