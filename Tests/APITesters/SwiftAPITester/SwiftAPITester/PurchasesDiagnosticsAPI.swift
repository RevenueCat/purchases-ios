//
//  PurchasesDiagnosticsAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 10/10/22.
//

import Foundation
import RevenueCat

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
func checkPurchasesDiagnostics() {
    let _: PurchasesDiagnostics = .default
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
private func checkPurchasesDiagnosticsAsync(_ diagnostics: PurchasesDiagnostics) async {
    _ = try? await diagnostics.testSDKHealth()
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.2, *)
func checkDiagnosticsErrors(_ error: PurchasesDiagnostics.Error) {
    switch error {
    case let .failedConnectingToAPI(error):
        print(error)

    case .invalidAPIKey:
        break

    case let .failedFetchingOfferings(error):
        print(error)

    case let .failedMakingSignedRequest(error):
        print(error)

    case let .unknown(error):
        print(error)

    @unknown default: break
    }
}
