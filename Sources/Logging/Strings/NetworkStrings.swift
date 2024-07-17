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
    case api_request_completed(
        _ request: HTTPRequest,
        httpCode: HTTPStatusCode,
        metadata: HTTPClient.ResponseMetadata?
    )
    case api_request_failed(_ request: HTTPRequest,
                            httpCode: HTTPStatusCode?,
                            error: NetworkError,
                            metadata: HTTPClient.ResponseMetadata?)
    case api_request_failed_status_code(HTTPStatusCode)
    case api_request_queued_for_retry(httpMethod: String,
                                      retryNumber: UInt,
                                      path: String,
                                      backoffInterval: TimeInterval)
    case api_request_failed_all_retries(httpMethod: String, path: String, retryCount: UInt)
    case reusing_existing_request_for_operation(CacheableNetworkOperation.Type, String)
    case enqueing_operation(CacheableNetworkOperation.Type, cacheKey: String)
    case creating_json_error(error: String)
    case json_data_received(dataString: String)
    case parsing_json_error(error: Error)
    case serial_request_done(httpMethod: String?, path: String?, queuedRequestsCount: Int)
    case serial_request_queued(httpMethod: String, path: String, queuedRequestsCount: Int)
    case starting_next_request(request: String)
    case starting_request(httpMethod: String, path: String)
    case retrying_request(httpMethod: String, path: String)
    case failing_url_resolved_to_host(url: URL, resolvedHost: String)
    case blocked_network(url: URL, newHost: String?)
    case api_request_redirect(from: URL, to: URL)
    case operation_state(NetworkOperation.Type, state: String)
    case request_handled_by_load_shedder(HTTPRequestPath)

    #if DEBUG
    case api_request_forcing_server_error(HTTPRequest)
    case api_request_forcing_signature_failure(HTTPRequest)
    case api_request_disabling_header_parameter_signature_verification(HTTPRequest)
    #endif

}

extension NetworkStrings: LogMessage {

    var description: String {
        switch self {
        case let .api_request_started(request):
            return "API request started: \(request.description)"

        case let .api_request_completed(request, httpCode, metadata):
            let prefix = "API request completed: \(request.description) (\(httpCode.rawValue))"

            if let metadata {
                return prefix + "\n" + metadata.description
            } else {
                return prefix
            }

        case let .api_request_failed(request, statusCode, error, metadata):
            let prefix = "API request failed: \(request.description) (\(statusCode?.rawValue.description ?? "<>")): " +
            "\(error.description)"

            if let metadata {
                return prefix + "\n" + metadata.description
            } else {
                return prefix
            }

        case let .api_request_failed_status_code(statusCode):
            return "API request failed with status code \(statusCode.rawValue)"

        case let .reusing_existing_request_for_operation(operationType, cacheKey):
            return "Network operation '\(operationType)' found with the same cache key " +
            "'\(cacheKey)'. Skipping request."

        case let .enqueing_operation(operationType, cacheKey):
            return "Enqueing network operation '\(operationType)' with cache key: '\(cacheKey)'"

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

        case let .failing_url_resolved_to_host(url, resolvedHost):
            return "Failing url '\(url)' resolved to host '\(resolvedHost)'"

        case let .blocked_network(url, newHost):
            return "It looks like requests to RevenueCat are being blocked. Context: We're attempting to connect " +
            "to \(url.absoluteString) host: (\(newHost ?? "<unable to resolve>")), " +
            "see: https://rev.cat/dnsBlocking for more info."

        case let .api_request_redirect(from, to):
            return "Performing redirect from '\(from.absoluteString)' to '\(to.absoluteString)'"

        case let .operation_state(operation, state):
            return "\(operation): \(state)"

        case let .request_handled_by_load_shedder(path):
            return "Request was handled by load shedder: \(path.relativePath)"

        case let .api_request_queued_for_retry(httpMethod, retryNumber, path, backoffInterval):
            return "Queued request \(httpMethod) \(path) for retry number \(retryNumber) in \(backoffInterval) seconds."

        case let .api_request_failed_all_retries(httpMethod, path, retryCount):
            return "Request \(httpMethod) \(path) failed all \(retryCount) retries."

        #if DEBUG
        case let .api_request_forcing_server_error(request):
            return "Returning fake HTTP 500 error for \(request.description)"

        case let .api_request_forcing_signature_failure(request):
            return "Returning fake signature verification failure for '\(request.description)'"

        case let .api_request_disabling_header_parameter_signature_verification(request):
            return "Disabling header parameter signature verification for '\(request.description)'"
        #endif
        }
    }

    var category: String { return "network" }

}

private extension HTTPRequest {

    var description: String {
        return "\(self.method.httpMethod) '\(self.path.relativePath)'"
    }

}

private extension HTTPClient.ResponseMetadata {

    var description: String {
        return "Request-ID: '\(self.requestID ?? "")'; " +
        "Amzn-Trace-ID: '\(self.amazonTraceID ?? "")'"
    }

}
