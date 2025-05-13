//
//  CustomerCenterUIKitView.swift
//  PaywallsTester
//
//  Created by Will Taylor on 12/6/24.
//

#if canImport(UIKit) && os(iOS)

import SwiftUI
import RevenueCat
import RevenueCatUI

/// Allows us to display the CustomerCenterViewController in a SwiftUI app
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
