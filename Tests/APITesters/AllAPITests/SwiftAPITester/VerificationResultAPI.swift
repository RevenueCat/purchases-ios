//
//  VerificationResultAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 2/10/23.
//

import Foundation
import RevenueCat

func checkVerificationResultAPI(_ mode: Configuration.EntitlementVerificationMode = .disabled,
                                _ result: VerificationResult = .notRequested) {
    let _: Bool = result.isVerified

    switch mode {
    case .disabled,
            .informational,
            .enforced:
        break

    @unknown default: break
    }

    switch result {
    case .notRequested,
            .verified,
            .verifiedOnDevice,
            .failed:
        break

    @unknown default: break
    }
}
