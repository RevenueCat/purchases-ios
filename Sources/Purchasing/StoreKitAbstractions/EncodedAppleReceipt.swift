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

}

extension EncodedAppleReceipt {

    func serialized() -> String {
        switch self {
        case .jws(let jws):
            return jws
        case .receipt(let data):
            return data.asFetchToken
        }
    }

}
