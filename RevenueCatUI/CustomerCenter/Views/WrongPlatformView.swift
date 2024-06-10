//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WrongPlatformView.swift
//
//
//  Created by Andrés Boedo on 5/3/24.
//

import Foundation
import RevenueCat
import SwiftUI

#if !os(macOS) && !os(tvOS) && !os(watchOS) && !os(visionOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
struct WrongPlatformView: View {

    @State
    private var store: Store?

    @Environment(\.openURL)
    private var openURL

    init() {
    }

    fileprivate init(store: Store) {
        self._store = State(initialValue: store)
    }

    var body: some View {
        VStack {

            switch store {
            case .appStore, .macAppStore, .playStore, .amazon:
                let platformName = humanReadablePlatformName(store: store!)

                Text("Your subscription is a \(platformName) subscription.")
                    .font(.title)
                    .padding()
                Text("Go the app settings on \(platformName) to manage your subscription and billing.")
                    .padding()
            default:
                Text("Please contact support to manage your subscription")
                    .font(.title)
                    .padding()
            }

        }
        .task {
            if store == nil {
                if let customerInfo = try? await Purchases.shared.customerInfo(),
                   let firstEntitlement = customerInfo.entitlements.active.first {
                    self.store = firstEntitlement.value.store
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
        case .stripe,
                .rcBilling,
                .external:
            return "Web"
        case .promotional:
            return "Free"
        case .amazon:
            return "Amazon Appstore"
        case .unknownStore:
            return "Unknown"
        }
    }

}

#if DEBUG

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
@available(macOS, unavailable)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
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

#endif

#endif
