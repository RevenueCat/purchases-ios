//
//  AnyCodingKey.swift
//  RevenueCat
//
//  Created by Dave DeLong on 7/16/26.
//

import Foundation

internal struct AnyCodingKey: CodingKey, CodingKeyRepresentable {

    let stringValue: String
    let intValue: Int?

    var codingKey: any CodingKey { self }

    init(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }

    init(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = Int(stringValue)
    }

    init?<T>(codingKey: T) where T : CodingKey {
        self.stringValue = codingKey.stringValue
        self.intValue = codingKey.intValue
    }

}

extension AnyCodingKey: ExpressibleByIntegerLiteral {

    init(integerLiteral value: Int) {
        self.init(intValue: value)
    }

}

extension AnyCodingKey: ExpressibleByStringLiteral {

    init(stringLiteral value: String) {
        self.init(stringValue: value)
    }

}
