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
extension Strings {

    enum NetworkStrings {

        static let api_request_completed = "API request completed with status: %@ %@ %d"
        static let api_request_started = "API request started: %@ %@"
        static let creating_json_error = "Error creating request with JSON body: %@ ; error: %@"
        static let creating_json_error_invalid = "JSON body is invalid: %@"
        static let json_data_received = "Data received: %@"
        static let parsing_json_error = "Error parsing JSON %@"
        static let serial_request_done = "Serial request done: %@ %@, %ld requests left in the queue"
        static let serial_request_queued = "There's a request currently running and %ld requests left in " +
            "the queue, queueing %@ %@"
        static let skproductsrequest_failed = "SKProductsRequest failed! error: %@"
        static let skproductsrequest_finished = "SKProductsRequest did finish"
        static let skproductsrequest_received_response = "SKProductsRequest request received response"
        static let starting_next_request = "Starting the next request in the queue, %@"
        static let starting_request = "There are no requests currently running, starting request %@ %@"
        static let retrying_request = "Retrying request %@ %@"
        static let could_not_find_cached_response =
            """
            We were expecting to be able to return a cached response, but we can't find it. Retrying call with a new ETag.
            """
        static let could_not_find_cached_response_in_already_retried =
            """
            We can't find the cached response, but call has already been retried. Returning result from backend %@.
            """

    }

}
