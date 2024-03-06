//
//  StoreKit2ReceiptInspector.swift
//  PurchaseTester
//
//  Created by Andrés Boedo on 3/6/24.
//

import Foundation

struct StoreKit2ReceiptVerifier {

    func fetchSK2Diagnostics(appConfigID: String, transactionID: String, token: String) async -> String {
        guard let url = URL(string: "https://api.revenuecat.com/toolkit/v1/app_configs/\(appConfigID)/sk2_diagnostics/\(transactionID)") else {
            return "Malformed URL!"
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted)
            return String(data: prettyData, encoding: .utf8) ?? "Error when decoding data into json. Data: \(data)"
        } catch {
            return "Fetching receipt information failed for transaction \(transactionID).\nError: \(error.localizedDescription)"
        }
    }

}
