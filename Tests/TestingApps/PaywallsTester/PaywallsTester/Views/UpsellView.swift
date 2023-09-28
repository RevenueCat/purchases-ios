//
//  LockedView.swift
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
                `.presentPaywallIfNeeded(requiredEntitlementIdentifier: \(Configuration.entitlement))
                """)

        }
        .padding()
        .presentPaywallIfNeeded(requiredEntitlementIdentifier: Configuration.entitlement)
    }
}

struct UpsellView_Previews: PreviewProvider {

    static var previews: some View {
        UpsellView()
    }

}
