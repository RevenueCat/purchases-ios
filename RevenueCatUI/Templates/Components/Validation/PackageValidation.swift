//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PackageValidation.swift
//
//  Created by Josh Holtz on 9/30/24.

import Foundation
import RevenueCat

#if PAYWALL_COMPONENTS

enum PackageValidation {

    static func findPackage(identifier: String, offering: Offering) throws -> Package {
        guard let package = offering.package(identifier: identifier) else {
            throw PackageValidationError.missingPackage(
                "Missing package from offering: \"\(identifier)\""
            )
        }

        return package
    }

}

enum PackageValidationError: Error {

    case missingPackage(String)

}

#endif
