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
    enum ReceiptType: Equatable {
        case jws(String), receipt(Data)
    }
    let type: ReceiptType

    init(jws: String) {
        self.type = .jws(jws)
    }

    init(receipt: Data) {
        self.type = .receipt(receipt)
    }
}

extension EncodedAppleReceipt {
    func serialized() -> String {
        switch type {
        case .jws(let jws):
            return jws
        case .receipt(let data):
            return data.asFetchToken
        }
    }
}
