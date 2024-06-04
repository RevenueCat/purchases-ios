//
// Created by Andrés Boedo on 8/11/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation
@testable import RevenueCat

class ASN1ObjectIdentifierEncoder {
    func objectIdentifierPayload(_ objectIdentifier: ASN1ObjectIdentifier) -> ArraySlice<UInt8> {
        return encodeASN1ObjectIdentifier(numbers: objectIdentifierNumbers(objectIdentifier))
    }

    // https://docs.microsoft.com/en-us/windows/win32/seccertenroll/about-object-identifier
    func encodeASN1ObjectIdentifier(numbers: [Int]) -> ArraySlice<UInt8> {
        var encodedNumbers: [UInt8] = []

        let firstValue = numbers[0]
        let secondValue = numbers[1]
        encodedNumbers.append(UInt8(firstValue * 40 + secondValue))

        for number in numbers.dropFirst(2) {
            encodedNumbers.append(contentsOf: encodeNumber(number))
        }

        return ArraySlice(encodedNumbers)
    }
}

private extension ASN1ObjectIdentifierEncoder {

    func objectIdentifierNumbers(_ objectIdentifier: ASN1ObjectIdentifier) -> [Int] {
        return objectIdentifier.rawValue.split(separator: ".").map { Int($0)! }
    }

    func encodeNumber(_ number: Int) -> [UInt8] {
        let numberAsBinaryString = String(number, radix: 2)
        let numberAsListOfBinaryStrings = splitNumbersStringIntoGroups(ofLength: 7, string: numberAsBinaryString)
        let bytes = stringArrayToBytes(numberAsListOfBinaryStrings)
        let encodedBytes = listByAddingOneToTheFirstBitOfAllButLast(numbers: bytes)
        return encodedBytes
    }

    func splitNumbersStringIntoGroups(ofLength length: Int, string: String) -> [String] {
        let totalInsignificantZeroesToAdd = length - (string.count % length)
        let insignificantZeroes = String(repeating: "0", count: totalInsignificantZeroesToAdd)
        let stringWithInsignificantZeroes = insignificantZeroes + string

        let totalGroups = stringWithInsignificantZeroes.count / length
        let groupsRange = 0..<totalGroups

        return groupsRange.map { groupIndex in
            let startIndex = groupIndex * length

            let rangeStart = String.Index(utf16Offset: startIndex, in: stringWithInsignificantZeroes)
            let rangeEnd = String.Index(utf16Offset: startIndex + length, in: stringWithInsignificantZeroes)

            return String(stringWithInsignificantZeroes[rangeStart..<rangeEnd])
        }
    }

    func listByAddingOneToTheFirstBitOfAllButLast(numbers: [UInt8]) -> [UInt8] {
        guard numbers.count > 0, let lastNumber = numbers.last else { return [] }
        return numbers.dropLast().map { $0 | (1 << 7) } + [lastNumber]
    }

    func stringArrayToBytes(_ stringArray: [String]) -> [UInt8] {
        stringArray.map { stringToBytes($0) }
    }

    func stringToBytes(_ string: String) -> UInt8 {
        UInt8(string, radix: 2)!
    }

}
