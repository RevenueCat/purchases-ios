//
//  UInt8+Extensions.swift
//  Purchases
//
//  Created by Andrés Boedo on 7/24/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

extension UInt8 {
    func bitAtIndex(_ index: UInt8) -> UInt8 {
        guard index <= 7 else { fatalError("invalid index: \(index)") }
        let shifted = self >> (7 - index)
        return shifted & 0b1
    }

    func valueInRange(from: UInt8, to: UInt8) -> UInt8 {
        guard to <= 7 else { fatalError("invalid index: \(to)") }
        guard from <= to else { fatalError("from: \(from) can't be greater than to: \(to)") }

        let range: UInt8 = to - from + 1
        let shifted = self >> (7 - to)
        let mask = maskForRange(range)
        return shifted & mask
    }
}

private extension UInt8 {
    func maskForRange(_ range: UInt8) -> UInt8 {
        guard 0 <= range && range <= 8 else { fatalError("range must be between 1 and 8") }
        switch range {
        case 1: return 0b1
        case 2: return 0b11
        case 3: return 0b111
        case 4: return 0b1111
        case 5: return 0b11111
        case 6: return 0b111111
        case 7: return 0b1111111
        case 8: return 0b11111111
        default:
            fatalError("unhandled range")
        }
    }
}
