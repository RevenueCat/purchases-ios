//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  EncodedAppleReceipt.swift
//  
//  Created by Mark Villacampa on 6/10/23.

import Foundation

/// Represents an `AppleReceipt` that's been encoded
/// in a suitable representation for the RevenueCat backend.
enum EncodedAppleReceipt: Equatable {

  case jws(String)
  case receipt(Data)
  case sk2receipt(StoreKit2Receipt)
  case empty

}

extension EncodedAppleReceipt: Codable {
    enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    enum ReceiptType: String, Codable {
        case jws
        case receipt
        case sk2receipt
        case empty
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ReceiptType.self, forKey: .type)

        switch type {
        case .jws:
            let value = try container.decode(String.self, forKey: .value)
            self = .jws(value)
        case .receipt:
            let base64String = try container.decode(String.self, forKey: .value)
            guard let data = Data(base64Encoded: base64String) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .value,
                    in: container,
                    debugDescription: "Invalid base64 string for receipt data"
                )
            }
            self = .receipt(data)
        case .sk2receipt:
            let value = try container.decode(StoreKit2Receipt.self, forKey: .value)
            self = .sk2receipt(value)
        case .empty:
            self = .empty
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .jws(let jws):
            try container.encode(ReceiptType.jws, forKey: .type)
            try container.encode(jws, forKey: .value)
        case .receipt(let data):
            try container.encode(ReceiptType.receipt, forKey: .type)
            try container.encode(data.base64EncodedString(), forKey: .value)
        case .sk2receipt(let receipt):
            try container.encode(ReceiptType.sk2receipt, forKey: .type)
            try container.encode(receipt, forKey: .value)
        case .empty:
            try container.encode(ReceiptType.empty, forKey: .type)
        }
    }
}

extension EncodedAppleReceipt {

    func serialized() -> String? {
        switch self {
        case .jws(let jws):
            return jws
        case .receipt(let data):
            return data.base64EncodedString()
        case .sk2receipt(let receipt):
            do {
                return try receipt.prettyPrintedData.base64EncodedString()
            } catch {
                Logger.warn(Strings.storeKit.sk2_error_encoding_receipt(error))
                return ""
            }
        case .empty:
            return nil
        }
    }

}
