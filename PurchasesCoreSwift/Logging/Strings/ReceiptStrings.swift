//
//  ReceiptStrings.swift
//  PurchasesCoreSwift
//
//  Created by Tina Nguyen on 12/11/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCReceipStrings) public class ReceiptStrings: NSObject {
    @objc public var data_object_identifer_not_found_receipt: String { "The data object identifier couldn't be found on the receipt" } //error
    @objc public var force_refreshing_receipt: String { "Force refreshing the receipt to get latest transactions from Apple." }  //debug
    @objc public var loaded_receipt: String { "Loaded receipt from url %@" }  //debug
    @objc public var no_sandbox_receipt_intro_eligibility: String { "App running on sandbox without a receipt file. Unable to determine into eligibility unless you've purchased before and there is a receipt available." }  //appleWarning
    @objc public var no_sandbox_receipt_restore: String { "App running in sandbox without a receipt file. Restoring transactions won't work until a purchase is made to generate a receipt. This should not happen in production unless user is logged out of Apple account." } //appleWarning
    @objc public var parse_receipt_locally_error: String { "There was an error when trying to parse the receipt locally, details: %@" } //error
    @objc public var parsing_receipt_failed: String { "%@-%@: Could not parse receipt, conservatively returning true" } //warn
    @objc public var parsing_receipt_success: String { "Receipt parsed successfully" } //info
    @objc public var parsing_receipt: String { "Parsing receipt" } //info
    @objc public var refreshing_empty_receipt: String { "Receipt empty, refreshing" }  //debug
    @objc public var unable_to_load_receipt: String { "Unable to load receipt, ensure you are logged in to a valid Apple account." }  //appleWarning
    @objc public var unknown_backend_error: String { "Unexpected backend error when posting receipt. Make sure you are on latest SDK version and let us know if problem persists." } //error
}
