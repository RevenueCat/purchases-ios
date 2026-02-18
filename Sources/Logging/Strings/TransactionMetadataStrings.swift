//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TransactionMetadataStrings.swift
//
//  Created by Antonio Pallares on 8/1/26.

import Foundation

// swiftlint:disable identifier_name
enum TransactionMetadataStrings {

    case metadata_already_exists_for_transaction(transactionId: String)
    case metadata_not_found_to_clear_for_transaction(transactionId: String)

}

extension TransactionMetadataStrings: LogMessage {

    var description: String {
        switch self {
        case let .metadata_already_exists_for_transaction(transactionId):
            return "Purchase data already cached for transaction identifier: \(transactionId). Skipping cache."

        case let .metadata_not_found_to_clear_for_transaction(transactionId):
            return "Purchase data not found in cache for transaction identifier \(transactionId) when trying to clear"
        }
    }

    var category: String { return "transactionMetadata" }
}
