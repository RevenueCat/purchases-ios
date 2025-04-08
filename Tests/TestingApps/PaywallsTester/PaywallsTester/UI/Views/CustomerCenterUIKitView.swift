//
//  CustomerCenterUIKitView.swift
//  PaywallsTester
//
//  Created by Will Taylor on 12/6/24.
//


import SwiftUI
import RevenueCat
import RevenueCatUI


#if os(iOS)
/// Allows us to display the CustomerCenterViewController in a SwiftUI app
@available(iOS 15.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
struct CustomerCenterUIKitView: UIViewControllerRepresentable {

    let customerCenterActionHandler: (CustomerCenterAction) -> Void

    func makeUIViewController(context: Context) -> CustomerCenterViewController {
        CustomerCenterViewController(
            customerCenterActionHandler: self.customerCenterActionHandler
        )
    }
    
    func updateUIViewController(_ uiViewController: CustomerCenterViewController, context: Context) {
        // No updates needed
    }
}
#endif
