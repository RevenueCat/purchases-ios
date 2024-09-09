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
