//
//  ArrayExtensions.swift
//
//
//  Created by Nacho Soto on 12/11/23.
//

import Foundation

public extension Sequence {

    /// Creates a `Dictionary` with the values in the receiver sequence, and the keys provided by `key`.
    /// - Precondition: The sequence must not have duplicate keys.
    func dictionaryWithKeys<Key>(_ key: @escaping (Element) -> Key) -> [Key: Element] {
        Dictionary(uniqueKeysWithValues: self.lazy.map { (key($0), $0) })
    }

}

#if PAYWALL_COMPONENTS
public extension Array where Element == PaywallComponent {

    func printComponents() {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.outputFormatting = .prettyPrinted

        do {
            let jsonData = try encoder.encode(self)

            // Convert JSON data to a string if needed for debugging or logging
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("JSON Representation:\n\(jsonString)")
            }

        } catch {
            print("Failed to encode components: \(error)")
        }
    }

}
#endif
