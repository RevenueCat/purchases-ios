//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WebBillingHTTPRequestPath.swift
//
//  Created by Toni Rico on 5/6/25.

import Foundation

extension HTTPRequest.WebBillingPath: HTTPRequestPath {

    // swiftlint:disable:next force_unwrapping
    static let serverHostURL = URL(string: "https://api.revenuecat.com")!

    var usesAPISources: Bool {
        return true
    }

    var authenticated: Bool {
        switch self {
        case .getWebOfferingProducts,
             .getWebBillingProducts,
             .postHostedCheckout:
            return true
        }
    }

    var shouldSendEtag: Bool {
        switch self {
        case .getWebOfferingProducts,
             .getWebBillingProducts:
            return true
        case .postHostedCheckout:
            // Every call creates a new checkout session, so there is never a cached response to revalidate.
            return false
        }
    }

    var supportsSignatureVerification: Bool {
        switch self {
        case .getWebOfferingProducts,
             .getWebBillingProducts,
             .postHostedCheckout:
            return false
        }
    }

    var needsNonceForSigning: Bool {
        switch self {
        case .getWebOfferingProducts,
             .getWebBillingProducts,
             .postHostedCheckout:
            return false
        }
    }

    var relativePath: String {
        switch self {
        case let .getWebOfferingProducts(appUserID):
            return "/rcbilling/v1/subscribers/\(appUserID.trimmedAndEscaped)/offering_products"
        case let .getWebBillingProducts(userId, productIds):
            let encodedUserId = userId.trimmedAndEscaped
            let encodedProductIds = productIds.map { productId in
                "id=\(productId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? productId)"
            }.joined(separator: "&")
            return "/rcbilling/v1/subscribers/\(encodedUserId)/products?\(encodedProductIds)"
        case .postHostedCheckout:
            return "/rcbilling/v1/hosted-checkout"
        }
    }

    var relativeIAMPath: String {
        switch self {
        case .getWebOfferingProducts:
            return "/rcbilling/v1/customer/offering_products"
        case let .getWebBillingProducts(userId: _, productIds: productIds):
            let encodedProductIds = productIds.map { productId in
                "id=\(productId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? productId)"
            }.joined(separator: "&")
            return "/rcbilling/v1/customer/products?\(encodedProductIds)"
        case .postHostedCheckout:
            // The customer is named in the body rather than the path, so there is nothing to leave out.
            return self.relativePath
        }
    }

    var name: String {
        switch self {
        case .getWebOfferingProducts:
            return "get_web_offering_products"
        case .getWebBillingProducts:
            return "get_web_products"
        case .postHostedCheckout:
            return "post_hosted_checkout"
        }
    }

}
