//
//  TemplateError.swift
//  
//
//  Created by Nacho Soto on 7/17/23.
//

import Foundation
import RevenueCat

/// Error produced when processing `PaywallData`.
enum TemplateError: Error {

    /// No packages available to create a paywall.
    case noPackages

    /// Paywall configuration contained no package types.
    case emptyPackageList

    /// No packages from the `PackageType` list could be found.
    case couldNotFindAnyPackages(expectedTypes: [String])

}

extension TemplateError: CustomNSError {

    var errorUserInfo: [String: Any] {
        return [
            NSLocalizedDescriptionKey: self.description
        ]
    }

    private var description: String {
        switch self {
        case .noPackages:
            return "Attempted to display paywall with no packages."

        case .emptyPackageList:
            return "Paywall configuration contains no packages."

        case let .couldNotFindAnyPackages(expectedTypes):
            return "Couldn't find any requested packages: \(expectedTypes)"
        }
    }

}
