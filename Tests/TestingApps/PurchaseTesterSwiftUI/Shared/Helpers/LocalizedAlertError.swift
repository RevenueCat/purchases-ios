//
//  LocalizedAlertError.swift
//  PurchaseTester
//
//  Created by Nacho Soto on 5/19/23.
//

import Foundation

struct LocalizedAlertError: LocalizedError {

    private let underlyingError: NSError

    var errorDescription: String? { self.title }
    var recoverySuggestion: String? { self.underlyingError.localizedRecoverySuggestion }

    init(_ error: Error) {
        self.underlyingError = error as NSError
    }

    var title: String {
        return "\(self.underlyingError.domain) \(self.underlyingError.code)"
    }

    var subtitle: String {
        return self.underlyingError.localizedDescription
    }

}
