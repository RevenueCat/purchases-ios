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
enum NetworkStrings {

    case api_request_completed(httpMethod: String, path: String, httpCode: Int)
    case api_request_started(httpMethod: String?, path: String?)
    case creating_json_error(requestBody: [String: Any], error: String)
    case creating_json_error_invalid(requestBody: [String: Any])
    case json_data_received(dataString: String)
    case parsing_json_error(error: Error)
    case serial_request_done(httpMethod: String?, path: String?, queuedRequestsCount: Int)
    case serial_request_queued(httpMethod: String, path: String, queuedRequestsCount: Int)
    case starting_next_request(request: String)
    case starting_request(httpMethod: String, path: String)
    case retrying_request(httpMethod: String, path: String)
    case could_not_find_cached_response
    case could_not_find_cached_response_in_already_retried(response: String)

}

extension NetworkStrings: CustomStringConvertible {

    var description: String {
        switch self {

        case let .api_request_completed(httpMethod, path, httpCode):
            return "API request completed with status: \(httpMethod) \(path) \(httpCode)"

        case let .api_request_started(httpMethod, path):
            return "API request started: \(httpMethod ?? "") \(path ?? "")"

        case let .creating_json_error(requestBody, error):
            return "Error creating request with JSON body: \(requestBody) ; error: \(error)"

        case .creating_json_error_invalid(let requestBody):
            return "JSON body is invalid: \(requestBody)"

        case .json_data_received(let dataString):
            return "Data received: \(dataString)"

        case .parsing_json_error(let error):
            return "Error parsing JSON \(error.localizedDescription)"

        case let .serial_request_done(httpMethod, path, queuedRequestsCount):
            return "Serial request done: \(httpMethod ?? "") \(path ?? ""), " +
                "\(queuedRequestsCount) requests left in the queue"

        case let .serial_request_queued(httpMethod, path, queuedRequestsCount):
            return "There's a request currently running and \(queuedRequestsCount) requests left in the queue, " +
                "queueing \(httpMethod) \(path)"

        case .starting_next_request(let request):
            return "Starting the next request in the queue, \(request)"

        case let .starting_request(httpMethod, path):
            return "There are no requests currently running, starting request \(httpMethod) \(path)"

        case let .retrying_request(httpMethod, path):
            return "Retrying request \(httpMethod) \(path)"

        case .could_not_find_cached_response:
            return "We were expecting to be able to return a cached response, but we can't find it. " +
                "Retrying call with a new ETag."

        case .could_not_find_cached_response_in_already_retried(let response):
            return "We can't find the cached response, but call has already been retried. " +
                "Returning result from backend \(response)"

        }
    }

}
