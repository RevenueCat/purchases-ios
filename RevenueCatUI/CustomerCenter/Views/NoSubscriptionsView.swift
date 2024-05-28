//
//  NoSubscriptionsView.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

import RevenueCat
import SwiftUI

@available(iOS 15.0, *)
struct NoSubscriptionsView: View {

    @Environment(\.dismiss) var dismiss
    @State private var showRestoreAlert: Bool = false

    var body: some View {
        VStack {
            Text("No Subscriptions found")
                .font(.title)
                .padding()
            Text("We can try checking your Apple account for any previously purchased products")
                .font(.body)
                .padding()

            Spacer()

            Button("Restore purchases") {
                showRestoreAlert = true
            }
            .restorePurchasesAlert(isPresented: $showRestoreAlert)
            .buttonStyle(ManageSubscriptionsButtonStyle())

            Button("Cancel") {
                dismiss()
            }

        }

    }

}

@available(iOS 15.0, *)
#Preview {
    NoSubscriptionsView()
}
