//
//  File.swift
//  
//
//  Created by Nacho Soto on 7/21/23.
//

import RevenueCat
import SwiftUI

struct LocalizedAlertError: LocalizedError {

    private let underlyingError: NSError

    init(error: NSError) {
        self.underlyingError = error
    }

    var errorDescription: String? {
        return "\(self.underlyingError.domain) \(self.underlyingError.code)"
    }

    var failureReason: String? {
        if let errorCode = self.underlyingError as? ErrorCode {
            return errorCode.description
        } else {
            return self.underlyingError.localizedDescription
        }
    }

    var recoverySuggestion: String? {
        self.underlyingError.localizedRecoverySuggestion
    }

}
