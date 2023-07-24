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

    @State
    private var isDisplayed = false

    var body: some View {
        Rectangle()
            .hidden()
            .sheet(isPresented: self.$isDisplayed) {
                PaywallView()
                #if os(macOS)
                    .frame(width: 460, height: 750)
                #endif
            }
            .onAppear {
                #if os(macOS)
                // macOS won't display this if called right away.
                DispatchQueue.main.async {
                    self.isDisplayed = true
                }
                #else
                self.isDisplayed = true
                #endif
            }
    }

}
