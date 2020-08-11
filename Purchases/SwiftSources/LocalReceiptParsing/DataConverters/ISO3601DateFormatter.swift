//
// Created by Andrés Boedo on 7/29/20.
// Copyright (c) 2020 Purchases. All rights reserved.
//

import Foundation

struct ISO3601DateFormatter {
    static let shared = ISO3601DateFormatter()

    private let dateFormatter = DateFormatter()

    private init() {
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ssZ"
    }

    func date(fromBytes bytes: ArraySlice<UInt8>) -> Date? {
        if let dateString = String(bytes: Array(bytes), encoding: .ascii) {
            return dateFormatter.date(from: dateString)
        }
        return nil
    }
}
