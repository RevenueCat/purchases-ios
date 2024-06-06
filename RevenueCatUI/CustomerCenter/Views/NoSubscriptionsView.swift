//
//  NoSubscriptionsView.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

import RevenueCat
import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct NoSubscriptionsView: View {

    @Environment(\.dismiss) var dismiss
    @State private var showRestoreAlert: Bool = false

    var body: some View {
        VStack {
            Text("No Subscriptions found")
                .font(.title)
                .padding()
            Text("We can try checking your Apple account for any previous purchases")
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct NoSubscriptionsView_Previews: PreviewProvider {

    static var previews: some View {
        NoSubscriptionsView()
    }

}
