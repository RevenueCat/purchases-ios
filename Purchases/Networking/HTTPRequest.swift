//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HTTPRequest.swift
//
//  Created by Juanpe Catalán on 8/7/21.
//

import Foundation

class HTTPRequest: NSCopying, CustomStringConvertible {

    let httpMethod: String
    let path: String
    let requestBody: [String: Any]?
    let authHeaders: [String: String]
    let completionHandler: ((Int, [String: Any]?, Error?) -> Void)?
    let retried: Bool
    let urlRequest: URLRequest

    convenience init(byCopyingRequest request: HTTPRequest, retried: Bool) {
        self.init(httpMethod: request.httpMethod,
                  path: request.path,
                  requestBody: request.requestBody,
                  authHeaders: request.authHeaders,
                  retried: request.retried,
                  urlRequest: request.urlRequest,
                  completionHandler: request.completionHandler)
    }

    required init(httpMethod: String,
                  path: String,
                  requestBody: [String: Any]?,
                  authHeaders: [String: String],
                  retried: Bool,
                  urlRequest: URLRequest,
                  completionHandler: ((Int, [String: Any]?, Error?) -> Void)?) {
        self.httpMethod = httpMethod
        self.path = path
        self.requestBody = requestBody
        self.authHeaders = authHeaders
        self.completionHandler = completionHandler
        self.retried = retried
        self.urlRequest = urlRequest
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let copy = HTTPRequest(
            httpMethod: httpMethod,
            path: path,
            requestBody: requestBody,
            authHeaders: authHeaders,
            retried: retried,
            urlRequest: urlRequest,
            completionHandler: completionHandler
        )

        return copy
    }

    var description: String {
        """
        <\(type(of: self)): httpMethod=\(httpMethod)
        path=\(path)
        requestBody=\(requestBody?.description ?? "(null)")
        headers=\(authHeaders.description )
        retried=\(retried)
        urlRequest=\(urlRequest.description)
        >
        """
    }

}
