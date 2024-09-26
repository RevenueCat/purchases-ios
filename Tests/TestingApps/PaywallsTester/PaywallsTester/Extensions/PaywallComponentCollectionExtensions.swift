//
//  PaywallComponentCollectionExtensions.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-09-05.
//

import Foundation
import RevenueCat

#if PAYWALL_COMPONENTS

extension Array where Element == PaywallComponent {

    func printAsJSON() {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = .prettyPrinted

        do {
            let jsonData = try encoder.encode(self)

            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Components as JSON:\n\(jsonString)")
            }

        } catch {
            print("Failed to convert components to JSON: \(error)")
        }
    }

}

extension Dictionary where Key == PaywallComponent.LocaleID, Value == PaywallComponent.LocalizationDictionary {

    func printAsJSON() {
//        do {
//            let jsonData = try JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
//            if let jsonString = String(data: jsonData, encoding: .utf8) {
//                print("Localization as JSON:\n\(jsonString)")
//            }
//        } catch {
//            print("Failed to convert localization to JSON: \(error)")
//        }
    }

}

#endif
