//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  SDKHealthCheckStatus+Icon.swift
//
//  Created by Pol Piella on 4/10/25.

#if DEBUG
import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
extension PurchasesDiagnostics.SDKHealthCheckStatus {
    var icon: some View {
        switch self {
        case .passed:
            return Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .failed:
            return Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        case .warning:
            return Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
        }
    }
}
#endif
