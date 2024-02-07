//
//  PurchasesDiagnosticsAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 10/10/22.
//

import Foundation
import RevenueCat

func checkPurchasesDiagnostics() {
    let _: PurchasesDiagnostics = .default
}

private func checkPurchasesDiagnosticsAsync(_ diagnostics: PurchasesDiagnostics) async {
    _ = try? await diagnostics.testSDKHealth()
}

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
