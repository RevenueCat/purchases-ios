//
//  HTTPRequest.swift
//  PurchasesCoreSwift
//
//  Created by Juanpe Catalán on 8/7/21.
//  Copyright © 2021 Purchases. All rights reserved.
//

import Foundation

public typealias HTTPClientResponseHandler = (Int, [String: Any]?, Error?) -> Void

// TODO(post migration): Change back to internal
@objc(RCHTTPRequest)
public class HTTPRequest: NSObject, NSCopying {
    @objc public let httpMethod: String
    @objc public let path: String
    @objc public let requestBody: [String: Any]?
    @objc public let headers: [String: String]?
    @objc public let completionHandler: HTTPClientResponseHandler?

    @objc(initWithHTTPMethod:path:body:headers:completionHandler:)
    public init(httpMethod: String, path: String, requestBody: [String: Any]?, headers: [String: String]?, completionHandler: HTTPClientResponseHandler?) {
        self.httpMethod = httpMethod
        self.path = path
        self.requestBody = requestBody
        self.headers = headers
        self.completionHandler = completionHandler
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = HTTPRequest(
            httpMethod: httpMethod,
            path: path,
            requestBody: requestBody,
            headers: headers,
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
        >
        """
    }
}
