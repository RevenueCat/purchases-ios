//
//  NoSubscriptionsView.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

import SwiftUI
import RevenueCat

@available(iOS 15.0, *)
public struct NoSubscriptionsView: View {

    @Environment(\.dismiss) var dismiss
    @State private var showRestoreAlert: Bool = false


    public var body: some View {
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

            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

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
