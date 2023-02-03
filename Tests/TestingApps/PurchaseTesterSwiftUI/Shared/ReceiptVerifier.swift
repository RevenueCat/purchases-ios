//
//  ReceiptVerifier.swift
//  ReceiptParserApp
//
//  Created by Andrés Boedo on 1/26/23.
//

import Foundation

struct ReceiptVerifier {

    private static let errorMessagesByCode = [
        21000: "The App Store could not read the JSON object you provided.",
        21002: "The data in the receipt-data property was malformed or missing.",
        21003: "The receipt could not be authenticated.",
        21004: "The shared secret you provided does not match the shared secret on file for your account.",
        21005: "The receipt server is not currently available.",
        21006: "This receipt is valid but the subscription has expired. When this status code is returned to your " +
        "server, the receipt data is also decoded and returned as part of the response. Only returned for " +
        "iOS 6 style transaction receipts for auto-renewable subscriptions.",
        21007: "This receipt is from the test environment, but it was sent to the production environment for " +
        "verification. Send it to the test environment instead.",
        21008: "This receipt is from the production environment, but it was sent to the test environment for " +
        "verification. Send it to the production environment instead.",
        21010: "This receipt could not be authorized. Treat this the same as if a purchase was never made."
    ]

    private static let internalDataAccessError = "Internal data access error."
    private static let internalDataAccessErrorRange = 21100...21199

    private static let sandboxUrl = URL(string: "https://sandbox.itunes.apple.com/verifyReceipt")!
    private static let productionUrl = URL(string: "https://buy.itunes.apple.com/verifyReceipt")!
    private static let receiptIsFromTestEnvironmentErrorCode = 21007

    func verifyReceipt(base64Encoded: String, sharedSecret: String? = nil, url: URL = Self.productionUrl) async -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        var parameters = [ "receipt-data": base64Encoded ]
        if let sharedSecret = sharedSecret, !sharedSecret.isEmpty {
            parameters["password"] = sharedSecret
        }

        guard let postData = (try? JSONSerialization.data(withJSONObject: parameters, options: [])) else {
            return "couldn't form parameters for http request to verify receipt. Params: \(parameters)"
        }
        request.httpBody = postData

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any]
                let status = json?["status"] as? Int
                if let status = status, status == Self.receiptIsFromTestEnvironmentErrorCode {
                    // receipt is a sandbox receipt, try with production url
                    return await self.verifyReceipt(base64Encoded: base64Encoded, sharedSecret: sharedSecret, url: Self.sandboxUrl)
                } else {
                    if let status = status, let errorMessage = errorMessage(from: status) {
                        return errorMessage
                    }
                    let jsonData = try JSONSerialization.data(withJSONObject: json ?? [:], options: .prettyPrinted)
                    let jsonString = String(data: jsonData, encoding: .utf8)
                    return jsonString ?? "Verify receipt result was empty for url: \(url)"
                }
            } catch {
                return "Verify receipt result parsing failed for url: \(url)\nError: \(error.localizedDescription)"
            }
        } catch {
            return "Verify receipt request failed for url: \(url)\nError: \(error.localizedDescription)"
        }
    }

    private func errorMessage(from code: Int) -> String? {
        if let message = Self.errorMessagesByCode[code] {
            return message
        }

        if Self.internalDataAccessErrorRange.contains(code) {
            return Self.internalDataAccessError
        }

        return nil
    }

}
