//
//  NetworkStrings.swift
//  PurchasesCoreSwift
//
//  Created by Tina Nguyen on 12/11/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCNetworkStrings) public class NetworkStrings: NSObject {
    @objc public var api_request_completed: String { "API request completed with status: %@ %@ %d" } //debug
    @objc public var api_request_started: String { "API request started: %@ %@" } //debug
    @objc public var creating_json_error: String { "Error creating request JSON: %@" } //error
    @objc public var json_data_received: String { "Data received: %@" } // rcError
    @objc public var parsing_json_error: String { "Error parsing JSON %@" } //rcError
    @objc public var serial_request_done: String { "Serial request done: %@ %@, %ld requests left in the queue" } //debug
    @objc public var serial_request_queue: String { "There's a request currently running and %ld requests left in the queue, queueing %@ %@" } //debug
    @objc public var skproductsrequest_failed: String {"SKProductsRequest failed! error: %@" } //appleError
    @objc public var skproductsrequest_finished: String { "SKProductsRequest did finish" } //rcSuccess
    @objc public var skproductsrequest_received_response: String { "SKProductsRequest request received response" } //rcSuccess
    @objc public var starting_next_request: String { "Starting the next request in the queue, %@" } //debug
    @objc public var starting_request: String { "There are no requests currently running, starting request %@ %@" } //debug
}
