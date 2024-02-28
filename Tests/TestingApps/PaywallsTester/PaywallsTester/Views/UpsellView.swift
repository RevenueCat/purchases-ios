//
//  UpsellView.swift
//  PaywallsTester
//
//  Created by Andrés Boedo on 9/28/23.
//

import SwiftUI

struct UpsellView: View {

    var body: some View {
        VStack {
            Text("""
                This view automatically displays the default paywall if you're not subscribed.
                
                This is achieved by calling
                `.presentPaywallIfNeeded(requiredEntitlementIdentifier: \(Configuration.entitlement))`
                """)

        }
        .padding()
//        .presentPaywallIfNeeded(
//            requiredEntitlementIdentifier: Configuration.entitlement,
//            purchaseStarted: {
//                print("Purchase started")
//            },
//            purchaseCompleted: { _ in
//                print("Purchase completed")
//            },
//            purchaseCancelled: {
//                print("Purchase cancelled")
//            },
//            onDismiss: {
//                print("Paywall dismissed")
//            },
//            onRestoreCompleted: { _ in
//                print("Restore completed")
//            },
//            onRestoreStarted: {
//                print("Restore started")
//            },
//            onRestoreFailure: {
//                print("Restore failed")
//            }
//        )
    }

}

struct UpsellView_Previews: PreviewProvider {

    static var previews: some View {
        UpsellView()
    }

}
