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

struct EncodedAppleReceipt: Equatable {
    enum ReceiptType {
        case jwt, receipt
    }
    let type: ReceiptType
    let data: Data
}

extension EncodedAppleReceipt {
    func serialized() -> String {
        switch type {
        case .jwt:
            return String(data: self.data, encoding: .utf8) ?? ""
        case .receipt:
            return self.data.asFetchToken
        }
    }
}
