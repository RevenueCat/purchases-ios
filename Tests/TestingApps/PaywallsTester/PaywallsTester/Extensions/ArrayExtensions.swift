//
//  ArrayExtensions.swift
//
//
//  Created by Nacho Soto on 12/11/23.
//

import Foundation
import RevenueCat

public extension Sequence {

    /// Creates a `Dictionary` with the values in the receiver sequence, and the keys provided by `key`.
    /// - Precondition: The sequence must not have duplicate keys.
    func dictionaryWithKeys<Key>(_ key: @escaping (Element) -> Key) -> [Key: Element] {
        Dictionary(uniqueKeysWithValues: self.lazy.map { (key($0), $0) })
    }

}

#if PAYWALL_COMPONENTS
public extension Array where Element == PaywallComponent {

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

extension Dictionary where Key == LocaleID, Value == LocalizationDictionary {
    func printAsJSON() {
        if let jsonData = try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            print("Localization as JSON:\n\(jsonString)")
        } else {
            print("Failed to convert localization to JSON: \(error)")
        }
    }
}

#endif
