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
  case simulatedStoreReceipt(SimulatedStoreReceipt)
  case empty

}

extension EncodedAppleReceipt {

    struct SimulatedStoreReceipt: Codable, Equatable {
        let transactionId: String
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
        case .simulatedStoreReceipt(let simulatedReceipt):
            do {
                return try simulatedReceipt.prettyPrintedData.base64EncodedString()
            } catch {
                // Logger.warn("Error encoding Test Store receipt: '\(error)'")
                return ""
            }
        case .empty:
            return nil
        }
    }

}
