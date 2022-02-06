//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PostSubscriberAttributesOperation.swift
//
//  Created by Joshua Liebowitz on 11/18/21.

import Foundation

class PostSubscriberAttributesOperation: NetworkOperation {

    private let subscriberAttributesMarshaller: SubscriberAttributesMarshaller
    private let subscriberAttributeHandler: SubscriberAttributeHandler
    private let configuration: UserSpecificConfiguration
    private let subscriberAttributes: SubscriberAttributeDict
    private let completion: SimpleResponseHandler?

    init(configuration: UserSpecificConfiguration,
         subscriberAttributes: SubscriberAttributeDict,
         completion: SimpleResponseHandler?,
         subscriberAttributesMarshaller: SubscriberAttributesMarshaller = SubscriberAttributesMarshaller(),
         subscriberAttributeHandler: SubscriberAttributeHandler = SubscriberAttributeHandler()) {
        self.configuration = configuration
        self.subscriberAttributes = subscriberAttributes
        self.completion = completion
        self.subscriberAttributesMarshaller = subscriberAttributesMarshaller
        self.subscriberAttributeHandler = subscriberAttributeHandler

        super.init(configuration: configuration)
    }

    override func begin() {
        post()
    }

    private func post() {
        guard self.subscriberAttributes.count > 0 else {
            Logger.warn(Strings.attribution.empty_subscriber_attributes)
            completion?(ErrorCode.emptySubscriberAttributes)
            self.finish()

            return
        }

        guard let appUserID = try? self.configuration.appUserID.escapedOrError() else {
            completion?(ErrorUtils.missingAppUserIDError())
            self.finish()

            return
        }

        let path = "/subscribers/\(appUserID)/attributes"

        let attributesInBackendFormat = self.subscriberAttributesMarshaller
            .map(subscriberAttributes: self.subscriberAttributes)
        httpClient.performPOSTRequest(serially: true,
                                      path: path,
                                      requestBody: ["attributes": attributesInBackendFormat],
                                      headers: self.authHeaders) { statusCode, response, error in
            defer {
                self.finish()
            }

            guard let completion = self.completion else {
                return
            }

            self.subscriberAttributeHandler.handleSubscriberAttributesResult(statusCode: statusCode,
                                                                             response: response,
                                                                             error: error,
                                                                             completion: completion)
        }
    }

}
