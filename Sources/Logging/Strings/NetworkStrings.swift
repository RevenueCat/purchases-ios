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

    case api_request_started(HTTPRequest)
    case api_request_completed(_ request: HTTPRequest, httpCode: HTTPStatusCode)
    case api_request_failed(_ request: HTTPRequest, error: NetworkError)
    case reusing_existing_request_for_operation(CacheableNetworkOperation.Type, String)
    case creating_json_error(error: String)
    case json_data_received(dataString: String)
    case parsing_json_error(error: Error)
    case serial_request_done(httpMethod: String?, path: String?, queuedRequestsCount: Int)
    case serial_request_queued(httpMethod: String, path: String, queuedRequestsCount: Int)
    case starting_next_request(request: String)
    case starting_request(httpMethod: String, path: String)
    case retrying_request(httpMethod: String, path: String)
    case could_not_find_cached_response
    case could_not_find_cached_response_in_already_retried(response: String)
    case failing_url_resolved_to_host(url: URL, resolvedHost: String)
    case blocked_network(url: URL, newHost: String?)

}

extension NetworkStrings: CustomStringConvertible {

    var description: String {
        switch self {
        case let .api_request_started(request):
            return "API request started: \(request.description)"

        case let .api_request_completed(request, httpCode):
            return "API request completed: \(request.description) (\(httpCode.rawValue))"

        case let .api_request_failed(request, error):
            return "API request failed: \(request.description): \(error.description)"

        case let .reusing_existing_request_for_operation(operationType, cacheKey):
            return "Network operation '\(operationType)' found with the same cache key " +
            "'\(cacheKey.prefix(15))...'. Skipping request."

        case let .creating_json_error(error):
            return "Error creating request with body: \(error)"

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

        case let .failing_url_resolved_to_host(url, resolvedHost):
            return "Failing url '\(url)' resolved to host '\(resolvedHost)'"

        case let .blocked_network(url, newHost):
            return "It looks like requests to RevenueCat are being blocked. Context: We're attempting to connect " +
            "to \(url.absoluteString) host: (\(newHost ?? "<unable to resolve>")), " +
            "see: https://rev.cat/dnsBlocking for more info."
        }
    }

}

private extension HTTPRequest {

    var description: String {
        return "\(self.method.httpMethod) \(self.path.url?.path ?? "")"
    }

}
