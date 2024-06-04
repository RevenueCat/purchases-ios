//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  LocalizedAlertError.swift
//
//  Created by Nacho Soto on 7/21/23.

import RevenueCat
import SwiftUI

struct LocalizedAlertError: LocalizedError {

    private let underlyingError: NSError

    init(error: NSError) {
        self.underlyingError = error
    }

    var errorDescription: String? {
        if self.underlyingError is ErrorCode {
            return "Error"
        } else {
            return "\(self.underlyingError.domain) \(self.underlyingError.code)"
        }
    }

    var failureReason: String? {
        if let errorCode = self.underlyingError as? ErrorCode {
            return "Error \(self.underlyingError.code): \(errorCode.description)"
        } else {
            return self.underlyingError.localizedDescription
        }
    }

    var recoverySuggestion: String? {
        self.underlyingError.localizedRecoverySuggestion
    }

}
