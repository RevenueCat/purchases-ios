//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  NetworkStrings.swift
//
//  Created by Tina Nguyen on 12/11/20.
//

import Foundation

// swiftlint:disable identifier_name
class NetworkStrings {

    var api_request_completed: String { "API request completed with status: %@ %@ %d" }
    var api_request_started: String { "API request started: %@ %@" }
    var creating_json_error: String { "Error creating request with JSON body: %@ ; error: %@" }
    var creating_json_error_invalid: String { "JSON body is invalid: %@" }
    var json_data_received: String { "Data received: %@" }
    var parsing_json_error: String { "Error parsing JSON %@" }
    var serial_request_done: String { "Serial request done: %@ %@, %ld requests left in the queue" }
    var serial_request_queued: String { "There's a request currently running and %ld requests left in " +
        "the queue, queueing %@ %@" }
    var skproductsrequest_failed: String {"SKProductsRequest failed! error: %@" }
    var skproductsrequest_finished: String { "SKProductsRequest did finish" }
    var skproductsrequest_received_response: String { "SKProductsRequest request received response" }
    var starting_next_request: String { "Starting the next request in the queue, %@" }
    var starting_request: String { "There are no requests currently running, starting request %@ %@" }
    var retrying_request: String { "Retrying request %@ %@" }
    var could_not_find_cached_response: String {
        """
        We were expecting to be able to return a cached response, but we can't find it. Retrying call with a new ETag.
        """
    }
    var could_not_find_cached_response_in_already_retried: String {
        """
        We can't find the cached response, but call has already been retried. Returning result from backend %@.
        """
    }

}
