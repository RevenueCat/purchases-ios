//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  ReceiptStrings.swift
//
//  Created by Tina Nguyen on 12/11/20.
//

import Foundation

// swiftlint:disable identifier_name
enum ReceiptStrings {

    static let data_object_identifer_not_found_receipt = "The data object identifier couldn't be found " +
        "on the receipt."
    static let force_refreshing_receipt = "Force refreshing the receipt to get latest transactions " +
        "from Apple."
    static let loaded_receipt = "Loaded receipt from url %@"
    static let no_sandbox_receipt_intro_eligibility = "App running on sandbox without a receipt file. " +
        "Unable to determine into eligibility unless you've purchased before and there is a receipt available."
    static let no_sandbox_receipt_restore = "App running in sandbox without a receipt file. Restoring " +
        "transactions won't work until a purchase is made to generate a receipt. This should not happen in " +
        "production unless user is logged out of Apple account."
    static let parse_receipt_locally_error = "There was an error when trying to parse the receipt " +
        "locally, details: %@"
    static let parsing_receipt_failed = "%@-%@: Could not parse receipt, conservatively returning true"
    static let parsing_receipt_success = "Receipt parsed successfully"
    static let parsing_receipt = "Parsing receipt"
    static let refreshing_empty_receipt = "Receipt empty, refreshing"
    static let unable_to_load_receipt = "Unable to load receipt, ensure you are logged in to a valid " +
        "Apple account."
    static let unknown_backend_error = "Unexpected backend error when posting receipt. Make sure you " +
        "are on latest SDK version and let us know if problem persists."

}
