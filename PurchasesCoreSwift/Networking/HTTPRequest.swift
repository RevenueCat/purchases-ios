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
    @objc public let headers: [String: String]?
    @objc public let completionHandler: ((Int, [AnyHashable: Any]?, Error?) -> Void)?
    @objc public let retried: Bool

    @objc public convenience init(RCHTTPRequest request: HTTPRequest, retried: Bool) {
        self.init(httpMethod: request.httpMethod,
                  path: request.path,
                  requestBody: request.requestBody,
                  headers: request.headers,
                  retried: request.retried,
                  completionHandler: request.completionHandler)
    }

    @objc(initWithHTTPMethod:path:body:headers:retried:completionHandler:)
    public required init(httpMethod: String,
                         path: String,
                         requestBody: [String: Any]?,
                         headers: [String: String]?,
                         retried: Bool,
                         completionHandler: ((Int, [AnyHashable: Any]?, Error?) -> Void)?) {
        self.httpMethod = httpMethod
        self.path = path
        self.requestBody = requestBody
        self.headers = headers
        self.completionHandler = completionHandler
        self.retried = retried
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = HTTPRequest(
            httpMethod: httpMethod,
            path: path,
            requestBody: requestBody,
            headers: headers,
            retried: retried,
            completionHandler: completionHandler
        )

        return copy
    }

    public override var description: String {
        """
        <\(type(of: self)): httpMethod=\(httpMethod)
        path=\(path)
        requestBody=\(requestBody?.description ?? "(null)")
        headers=\(headers?.description ?? "(null)")
        retried=\(retried)
        >
        """
    }
}
