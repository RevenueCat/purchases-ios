//
//  HTTPRequest.swift
//  PurchasesCoreSwift
//
//  Created by Juanpe Catalán on 8/7/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

// TODO(post migration): Change back to internal
@objc(RCHTTPRequest)
public class HTTPRequest: NSObject, NSCopying {
    @objc public let httpMethod: String
    @objc public let path: String
    @objc public let requestBody: [String: Any]?
    @objc public let authHeaders: [String: String]
    @objc public let completionHandler: ((Int, [String: Any]?, Error?) -> Void)?
    @objc public let retried: Bool
    let urlRequest: URLRequest

    @objc public convenience init(byCopyingRequest request: HTTPRequest, retried: Bool) {
        self.init(httpMethod: request.httpMethod,
                  path: request.path,
                  requestBody: request.requestBody,
                  authHeaders: request.authHeaders,
                  retried: request.retried,
                  urlRequest: request.urlRequest,
                  completionHandler: request.completionHandler)
    }

    @objc(initWithHTTPMethod:path:body:headers:retried:urlRequest:completionHandler:)
    public required init(httpMethod: String,
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

    public func copy(with zone: NSZone? = nil) -> Any {
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

    public override var description: String {
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
