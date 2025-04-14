//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  InvalidProductErrorPayload+StatusMessage.swift
//
//  Created by Pol Piella on 4/10/25.

import Foundation

extension PurchasesDiagnostics.ProductDiagnosticsPayload {
    var statusMessage: String {
        switch self.status {
        case .valid:
            return "Available for production purchases."
        case .couldNotCheck:
            return self.description
        case .notFound:
            return """
                Product not found in App Store Connect. You need to create a product with identifier: \
                '\(self.identifier)' in App Store Connect to use it for production purchases.
                """
        case .actionInProgress:
            return """
                Some process is ongoing and needs to be completed before using this product in production purchases, \
                by Apple (state: \(self.description)). \
                You can still make test purchases with the RevenueCat SDK, but you will need to \
                wait for the state to change before you can make production purchases.
                """
        case .needsAction:
            return """
                This product's status (\(self.description)) requires you to take action in App Store Connect \
                before using it in production purchases.
                """
        case .unknown:
            return """
                We could not check the status of your product using the App Store Connect API. \
                Please check the app's credentials in the dashboard and try again.
                """
        }
    }
}
