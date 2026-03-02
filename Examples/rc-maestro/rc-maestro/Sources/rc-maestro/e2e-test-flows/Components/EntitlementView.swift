//
//  EntitlementView.swift
//  Maestro
//
//  Created by Rick van der Linden on 10/11/2025.
//  Copyright © 2025 RevenueCat, Inc. All rights reserved.
//

import SwiftUI
@testable import RevenueCat

struct EntitlementView: View {
    let identifier: String
    
    var entitlement: EntitlementInfo? {
        customerInfo?.entitlements.all[identifier]
    }
    
    @State private var customerInfo: CustomerInfo?
    
    var body: some View {
        VStack {
            if let entitlement {
                if entitlement.isActive {
                    Text("entitlement (\(entitlement.identifier)): active")
                } else {
                    Text("entitlement (\(entitlement.identifier)): inactive")
                }
            }
            else {
                Text("entitlement (\(identifier)): nil")
            }

            if let entitlement {
                Text("verification: " + entitlement.verification.stringValue)
            }
            if let customerInfo {
                Text("customer info source: " + customerInfo.originalSource.rawValue)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.5))
        .padding()
        .task {
            for await customerInfo in Purchases.shared.customerInfoStream {
                self.customerInfo = customerInfo
            }
        }
    }
}

fileprivate extension VerificationResult {
    var stringValue: String {
        switch self {
        case .notRequested:
            return "not_requested"
        case .verified:
            return "verified"
        case .verifiedOnDevice:
            return "verified_on_device"
        case .failed:
            return "failed"
        }
    }
}
