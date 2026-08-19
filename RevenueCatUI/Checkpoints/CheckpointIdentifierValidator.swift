//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointIdentifierValidator.swift
//
//  Created by Rick van der Linden.
//

enum CheckpointIdentifierValidator {

    static func isValid(_ identifier: String) -> Bool {
        let characters = identifier.utf8

        guard
            (1...100).contains(characters.count),
            let firstCharacter = characters.first,
            Self.isASCIILetter(firstCharacter)
        else {
            return false
        }

        return characters.dropFirst().allSatisfy(Self.isAllowedCharacter)
    }

    private static func isAllowedCharacter(_ character: UInt8) -> Bool {
        return Self.isASCIILetter(character)
            || (UInt8(ascii: "0")...UInt8(ascii: "9")).contains(character)
            || character == UInt8(ascii: "_")
            || character == UInt8(ascii: "-")
    }

    private static func isASCIILetter(_ character: UInt8) -> Bool {
        return (UInt8(ascii: "a")...UInt8(ascii: "z")).contains(character)
            || (UInt8(ascii: "A")...UInt8(ascii: "Z")).contains(character)
    }

}
