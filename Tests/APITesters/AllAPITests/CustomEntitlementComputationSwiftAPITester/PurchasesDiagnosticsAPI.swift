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

#if DEBUG
private func checkPurchasesDiagnosticsAsync(_ diagnostics: PurchasesDiagnostics) async {
    try? await diagnostics.checkSDKHealth()
}

func checkHealthReportErrors(_ error: PurchasesDiagnostics.SDKHealthError) {
    switch error {
    case .invalidAPIKey:
        break
    case .noOfferings:
        break
    case .offeringConfiguration(let offerings):
        let copy: [PurchasesDiagnostics.OfferingDiagnosticsPayload] = offerings

        copy.forEach {
            let _: String = $0.identifier
            let packages: [PurchasesDiagnostics.OfferingPackageDiagnosticsPayload] = $0.packages
            packages.forEach { package in
                let _: String = package.identifier
                let _: String? = package.title
                let _: PurchasesDiagnostics.ProductStatus = package.status
                let _: String = package.description
                let _: String = package.productIdentifier
                let _: String? = package.productTitle
            }

            let _: PurchasesDiagnostics.SDKHealthCheckStatus = $0.status
            switch $0.status {
            case .passed: break
            case .failed: break
            case .warning: break
            }
        }
    case .invalidBundleId(let invalidBundleIdErrorPayload):
        guard let copy: PurchasesDiagnostics.InvalidBundleIdErrorPayload = invalidBundleIdErrorPayload else {
            return
        }

        let _: String = copy.appBundleId
        let _: String = copy.sdkBundleId
    case .invalidProducts(let products):
        let copy: [PurchasesDiagnostics.ProductDiagnosticsPayload] = products

        copy.forEach {
            let _: String = $0.identifier
            let _: String? = $0.title
            let _: PurchasesDiagnostics.ProductStatus = $0.status
            let _: String = $0.description

            switch $0.status {
            case .valid,
                 .couldNotCheck,
                 .notFound,
                 .actionInProgress,
                 .needsAction,
                 .unknown:
                break
            }
        }
    case .notAuthorizedToMakePayments:
        break
    case .unknown(let error):
        let _: Swift.Error = error
    }
}
#endif
