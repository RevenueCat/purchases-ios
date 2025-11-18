//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EmailValidator.swift
//
//  Created by Rosie Watson on 11/18/2025

import Foundation

enum EmailValidator {

    static func isValid(_ email: String) -> Bool {
        // Basic checks
        guard !email.isEmpty else { return false }
        guard !email.contains("..") else { return false }
        guard email.filter({ $0 == "@" }).count == 1 else { return false }

        // Regex validation
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

}
