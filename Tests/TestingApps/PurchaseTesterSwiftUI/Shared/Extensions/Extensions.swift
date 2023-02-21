//
//  Extensions.swift
//  PurchaseTester
//
//  Created by Nacho Soto on 10/25/22.
//

import Foundation

import RevenueCat

extension String {

    var nonEmpty: String? {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)

        return trimmed.isEmpty
            ? nil
            : trimmed
    }

}

extension Configuration.EntitlementVerificationMode {

    var label: String {
        switch self {
        case .disabled: return "Disabled"
        case .informational: return "Information Only"
        case .enforced: return "Enforced"
        }
    }

    static let all: [Self] = [
        .disabled,
        .informational,
        .enforced
    ]

}

extension Configuration.EntitlementVerificationMode: Identifiable {

    public var id: Int { return self.rawValue }

}

extension VerificationResult: CustomStringConvertible {

    public var description: String {
        switch self {
        case .notVerified: return "Not verified"
        case .verified: return "Verified"
        case .failed: return "Failed verification"
        }
    }

}
