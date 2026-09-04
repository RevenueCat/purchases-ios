//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  Dictionary+DimensionValue.swift
//
//  Created by Rick van der Linden on 9/2/26.
//

import Foundation

extension Dictionary where Key == String, Value == DimensionValue {

    mutating func set(_ key: String, string: String?) {
        guard let string, !string.isEmpty else { return }
        self[key] = .string(string)
    }

    mutating func set(_ key: String, date: Date?) {
        guard let date else { return }
        self[key] = .date(date)
    }

    mutating func set(price: ProductPaidPrice?) {
        guard let price else { return }

        let amountMicros = price.amount * 1_000_000
        if amountMicros.isFinite,
           amountMicros >= Double(Int64.min),
           amountMicros < Double(Int64.max) {
            self["price_amount_micros"] = .int(Int64(amountMicros))
        }
        if !price.currency.isEmpty {
            self["price_currency"] = .string(price.currency)
        }
    }

}
