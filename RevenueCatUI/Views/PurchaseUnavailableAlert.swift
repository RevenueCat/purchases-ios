//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PurchaseUnavailableAlert.swift
//
//  Created by Antonio Pallares on 25/9/26.

import SwiftUI

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension View {

    /// Tells the customer the purchase they tapped is not available to them, so a button that opens nothing
    /// does not look broken.
    func purchaseUnavailableAlert(isPresented: Binding<Bool>, localizedBundle: Bundle) -> some View {
        self.alert(
            Text("Purchase unavailable", bundle: localizedBundle),
            isPresented: isPresented
        ) {
            Button {
                isPresented.wrappedValue = false
            } label: {
                Text("OK", bundle: localizedBundle)
            }
        } message: {
            Text("This purchase isn't available in your region.", bundle: localizedBundle)
        }
    }

}
