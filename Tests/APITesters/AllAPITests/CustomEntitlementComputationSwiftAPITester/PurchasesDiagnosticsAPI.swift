//
//  PurchasesDiagnosticsAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 10/10/22.
//

import Foundation
import RevenueCat_CustomEntitlementComputation

func checkPurchasesDiagnostics() {
    let _: PurchasesDiagnostics = .default
}

private func checkPurchasesDiagnosticsAsync(_ diagnostics: PurchasesDiagnostics) async {
    try? await diagnostics.checkSDKHealth()
}

@available(*, deprecated) // Ignore deprecation warnings
private func checkDeprecatedPurchasesDiagnosticsAsync(_ diagnostics: PurchasesDiagnostics) async {
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
    }
}

func checkHealthReportErrors(_ error: PurchasesDiagnostics.SDKHealthError) {
    switch error {
    case .invalidAPIKey:
        break
    case .noOfferings:
        break
    case .offeringConfiguration(let offerings):
        print(offerings)
    case .invalidBundleId(let invalidBundleIdErrorPayload):
        if let invalidBundleIdErrorPayload { print(invalidBundleIdErrorPayload) }
    case .invalidProducts(let products):
        print(products)
    case .notAuthorizedToMakePayments:
        break
    case .unknown(let error):
        print(error)
    }
}
