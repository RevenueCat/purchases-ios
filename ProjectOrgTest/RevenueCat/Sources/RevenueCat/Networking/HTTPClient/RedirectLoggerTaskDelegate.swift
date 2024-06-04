//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RedirectLoggerSessionDelegate.swift
//
//  Created by Nacho Soto on 3/23/23.

import Foundation

/// Implementation of `URLSessionTaskDelegate` that logs when the task will perform a redirection.
final class RedirectLoggerSessionDelegate: NSObject, URLSessionTaskDelegate {

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        if let responseURL = response.url, let requestURL = request.url {
            Logger.debug(Strings.network.api_request_redirect(from: responseURL,
                                                              to: requestURL))
        }

        completionHandler(request)
    }

}
