//
//  NetworkStrings.swift
//  PurchasesCoreSwift
//
//  Created by Tina Nguyen on 12/11/20.
//  Copyright © 2020 Purchases. All rights reserved.
//

import Foundation

@objc(RCNetworkStrings) public class NetworkStrings: NSObject {
    @objc public var api_request_completed: String { "API request completed with status: %@ %@ %d" }
    @objc public var api_request_started: String { "API request started: %@ %@" }
    @objc public var creating_json_error: String { "Error creating request with JSON body: %@" }
    @objc public var json_data_received: String { "Data received: %@" }
    @objc public var parsing_json_error: String { "Error parsing JSON %@" }
    @objc public var serial_request_done: String { "Serial request done: %@ %@, %ld requests left in the queue" }
    @objc public var serial_request_queued: String { "There's a request currently running and %ld requests left in " +
        "the queue, queueing %@ %@" }
    @objc public var skproductsrequest_failed: String {"SKProductsRequest failed! error: %@" }
    @objc public var skproductsrequest_finished: String { "SKProductsRequest did finish" }
    @objc public var skproductsrequest_received_response: String { "SKProductsRequest request received response" }
    @objc public var starting_next_request: String { "Starting the next request in the queue, %@" }
    @objc public var starting_request: String { "There are no requests currently running, starting request %@ %@" }
}
