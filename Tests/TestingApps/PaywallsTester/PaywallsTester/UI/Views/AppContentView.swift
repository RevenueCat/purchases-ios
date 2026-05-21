//
//  AppContentView.swift
//  PaywallsTester
//
//  Created by Nacho Soto on 7/13/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

struct AppContentView: View {

    var body: some View {
        if Purchases.isConfigured {
            APIKeyDashboardList()
        } else {
            Text("Purchases is not configured")
        }
    }

}
