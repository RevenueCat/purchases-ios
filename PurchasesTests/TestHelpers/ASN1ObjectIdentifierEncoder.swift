//
// Created by Andrés Boedo on 8/11/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
@testable import Purchases

class ASN1ObjectIdentifierEncoder {
    func objectIdentifierPayload(_ objectIdentifier: ASN1ObjectIdentifier) -> ArraySlice<UInt8> {
        return encodeASN1ObjectIdentifier(numbers: objectIdentifierNumbers(objectIdentifier))
    }

    func encodeASN1ObjectIdentifier(numbers: [Int]) -> ArraySlice<UInt8> {
        // https://docs.microsoft.com/en-us/windows/win32/seccertenroll/about-object-identifier

        var encodedNumbers: [UInt8] = []

        let firstValue = numbers[0]
        let secondValue = numbers[1]
        encodedNumbers.append(UInt8(firstValue * 40 + secondValue))
        for number in numbers.dropFirst(2) {
            if number < 127 {
                encodedNumbers.append(UInt8(number))
            } else {
                let numberAsBytes = encodeLongNumber(number: number)
                encodedNumbers.append(contentsOf: numberAsBytes)
            }
        }

        return ArraySlice(encodedNumbers)
    }
}

private extension ASN1ObjectIdentifierEncoder {

    func objectIdentifierNumbers(_ objectIdentifier: ASN1ObjectIdentifier) -> [Int] {
        return objectIdentifier.rawValue.split(separator: ".").map { Int($0)! }
    }

    func encodeLongNumber(number: Int) -> [UInt8] {
        let numberAsBinaryString = String(number, radix: 2)
        let numberAsListOfBinaryStrings = splitStringIntoGroups(ofLength: 7, string: numberAsBinaryString)
        let bytes = numberAsListOfBinaryStrings.map { UInt8($0, radix: 2)! }
        let encodedBytes = listByAddingOneToTheFirstBitOfAllButLast(numbers: bytes)
        return encodedBytes
    }

    func splitStringIntoGroups(ofLength length: Int, string: String) -> [String] {
        guard length > 0 else { return [] }

        let totalGroups: Int = (string.count + length - 1) / length
        let range = 0..<totalGroups
        let indices = range.map { length * $0..<min(length * ($0 + 1), string.count) }
        return indices
            .map { string.reversed()[$0.startIndex..<$0.endIndex] } // 1. reverse so we start counting from the right
            .map { String.init($0.reversed()) } // 2. reverse again to form each string
            .reversed() // 3. reverse the whole list to undo the change of step 1
    }

    func listByAddingOneToTheFirstBitOfAllButLast(numbers: [UInt8]) -> [UInt8] {
        guard numbers.count > 0, let lastNumber = numbers.last else { return [] }
        return numbers.dropLast().map { $0 | (1 << 7) } + [lastNumber]
    }
}