//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SDKHealthStatus+Icon.swift
//
//  Created by Pol Piella on 4/10/25.

#if DEBUG
import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
extension PurchasesDiagnostics.SDKHealthStatus {
    var icon: some View {
        switch self {
        case let .healthy(warnings):
            return Image(systemName: warnings.count > 0
                         ? "checkmark.circle.badge.questionmark.fill"
                         : "checkmark.circle.fill")
                .foregroundColor(.green)
        case .unhealthy:
            return Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        }

    }
}
#endif
