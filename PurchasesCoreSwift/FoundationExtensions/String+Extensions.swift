//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  String+Extensions.swift
//
//  Created by Juanpe Catalán on 9/7/21.
//

import Foundation

extension String {

    func rot13() -> String {
        ROT13.string(self)
    }

}

// swiftlint:disable identifier_name
private struct ROT13 {

    private static var key = [Character: Character]()

    private static let uppercase = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    private static let lowercase = Array("abcdefghijklmnopqrstuvwxyz")

    fileprivate static func string(_ string: String) -> String {
        if ROT13.key.isEmpty {
            for i in 0 ..< 26 {
                ROT13.key[ROT13.uppercase[i]] = ROT13.uppercase[(i + 13) % 26]
                ROT13.key[ROT13.lowercase[i]] = ROT13.lowercase[(i + 13) % 26]
            }
        }

        let transformed = string.map { ROT13.key[$0] ?? $0 }
        return String(transformed)
    }

}
