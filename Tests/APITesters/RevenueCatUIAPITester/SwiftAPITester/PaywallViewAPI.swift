//
//  PaywallViewAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 7/14/23.
//

import RevenueCat
import RevenueCatUI
import SwiftUI

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct App: View {

    private var offering: Offering
    private var paywall: PaywallData

    var body: some View {
        PaywallView(offering: self.offering, paywall: self.paywall)
    }

}
