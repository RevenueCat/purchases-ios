//
//  OtherAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 5/31/23.
//

import Foundation

import RevenueCat
import StoreKit
import SwiftUI

#if DEBUG && swift(>=5.8) && (os(iOS) || os(macOS) || VISION_OS)

@available(iOS 16.0, macOS 13.0, *)
struct AppView: View {

    @State private var debugOverlayVisible: Bool = false

    var body: some View {
        EmptyView()
            .debugRevenueCatOverlay()
            .debugRevenueCatOverlay(isPresented: self.$debugOverlayVisible)
    }

}

#endif

#if DEBUG && os(iOS) && swift(>=5.8)

@available(iOS 16.0, *)
func debugViewController() {
    let _: UIViewController = DebugViewController()
    UIViewController().presentDebugRevenueCatOverlay()
    UIViewController().presentDebugRevenueCatOverlay(animated: false)
}

#endif

#if swift(>=5.9)

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
struct PaywallViews: View {

    let offering: Offering

    var body: some View {
        StoreView.forOffering(self.offering)
        StoreView.forOffering(self.offering, prefersPromotionalIcon: true)

        StoreView.forOffering(
            self.offering,
            prefersPromotionalIcon: true,
            icon: { (_: Product) in Text("") },
            placeholderIcon: { Text("") }
        )

        SubscriptionStoreView.forOffering(self.offering)
        SubscriptionStoreView.forOffering(self.offering) {
            Text("Marketing content")
        }
    }

}

#endif
