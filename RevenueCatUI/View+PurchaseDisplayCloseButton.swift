//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  View+PurchaseDisplayCloseButton.swift
//  Created by Seyed Mojtaba Hosseini Zeidabadi on 11/15/25.
//

import RevenueCat
import SwiftUI

extension View {
    /// Overrides default `DisplayCloseButton` of the paywall.
    /// Pass `nil` to remove the override.
    func purchaseDisplayCloseButton(_ displayCloseButton: Bool?) -> some View {
        environment(\.purchaseDisplayCloseButton, displayCloseButton)
    }
}
