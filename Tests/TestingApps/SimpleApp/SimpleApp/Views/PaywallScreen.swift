//
//  PaywallScreen.swift
//  SimpleApp
//
//  Created by Nacho Soto on 7/13/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

struct PaywallScreen: View {

    var offering: Offering
    var paywall: PaywallData

    @State
    private var isDisplayed = false

    var body: some View {
        Rectangle()
            .hidden()
            .sheet(isPresented: self.$isDisplayed) {
                PaywallView(offering: self.offering, paywall: self.paywall)
            }
            .onAppear {
                self.isDisplayed = true
            }
    }

}
