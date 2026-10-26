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

    struct Content {

        let title: String
        let message: String

        init(error: NSError) {
            self.title = "Error"

            if let errorCode = error as? ErrorCode {
                self.message = "Error \(error.code): \(errorCode.description)"
            } else {
                self.message = error.localizedDescription
            }
        }

    }

    private let underlyingError: NSError
    private let content: Content

    init(error: NSError) {
        self.underlyingError = error
        self.content = .init(error: error)
    }

    var errorDescription: String? {
        return self.content.title
    }

    var failureReason: String? {
        return self.content.message
    }

    var recoverySuggestion: String? {
        self.underlyingError.localizedRecoverySuggestion
    }

}
