//
//  WrongPlatformView.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

import Foundation
import RevenueCat
import SwiftUI

@available(iOS 15.0, *)
public struct WrongPlatformView: View {

    @State
    private var store: Store?

    @Environment(\.openURL)
    private var openURL

    public init() {
        self._store = State(initialValue: nil)
    }

    public init(store: Store) {
        self._store = State(initialValue: store)
    }

    public var body: some View {
        VStack {

            switch store {
            case .appStore, .macAppStore, .playStore, .amazon:
                let platformName = humanReadablePlatformName(store: store!)

                Text("Your subscription is being billed through \(platformName).")
                    .font(.title)
                    .padding()
                Text("Go the app settings on \(platformName) to manage your subscription and billing.")
                    .padding()
            default:
                Text("Please contact support to manage your subscription")
                    .font(.title)
                    .padding()
            }

            Spacer()

            Button("Contact support") {
                Task {
                    openURL(URLUtilities.createMailURL()!)
                }
            }
            .padding()

        }
        .onAppear {
            if store == nil {
                Task {
                    if let customerInfo = try? await Purchases.shared.customerInfo(),
                       let firstEntitlement = customerInfo.entitlements.active.first {
                        self.store = firstEntitlement.value.store
                    }
                }
            }
        }
    }

    private func humanReadablePlatformName(store: Store) -> String {
            switch store {
            case .appStore, .macAppStore:
                return "Apple App Store"
            case .playStore:
                return "Google Play Store"
            case .stripe:
                return "Stripe"
            case .promotional:
                return "Promotional"
            case .amazon:
                return "Amazon Appstore"
            case .rcBilling:
                return "RCBilling"
            case .external:
                return "External"
            case .unknownStore:
                return "Unknown"
            }
        }

}

@available(iOS 15.0, *)
struct WrongPlatformView_Previews: PreviewProvider {

    static var previews: some View {
        Group {
            WrongPlatformView(store: .appStore)
                .previewDisplayName("App Store")

            WrongPlatformView(store: .rcBilling)
                .previewDisplayName("RCBilling")
        }

    }

}
