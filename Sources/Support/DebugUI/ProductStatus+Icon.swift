//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ProductStatus+Icon.swift
//
//  Created by Pol Piella on 4/10/25.

import SwiftUI

@available(iOS 16.0, macOS 13.0, *)
extension PurchasesDiagnostics.ProductStatus {
    var icon: some View {
        switch self {
        case .valid:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .couldNotCheck, .unknown:
            Image(systemName: "questionmark.circle.fill")
                .foregroundColor(.gray)
        case .notFound:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        case .actionInProgress, .needsAction:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)
        }
    }
}
