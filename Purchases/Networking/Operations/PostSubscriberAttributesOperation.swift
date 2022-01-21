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
    private let completion: PostRequestResponseHandler?

    init(configuration: UserSpecificConfiguration,
         subscriberAttributes: SubscriberAttributeDict,
         completion: PostRequestResponseHandler?,
         subscriberAttributesMarshaller: SubscriberAttributesMarshaller = SubscriberAttributesMarshaller(),
         subscriberAttributeHandler: SubscriberAttributeHandler = SubscriberAttributeHandler()) {
        self.configuration = configuration
        self.subscriberAttributes = subscriberAttributes
        self.completion = completion
        self.subscriberAttributesMarshaller = subscriberAttributesMarshaller
        self.subscriberAttributeHandler = subscriberAttributeHandler

        super.init(configuration: configuration)
    }

    override func main() {
        if self.isCancelled {
            return
        }

        post(subscriberAttributes: self.subscriberAttributes,
             appUserID: self.configuration.appUserID,
             completion: self.completion)
    }

    func post(subscriberAttributes: SubscriberAttributeDict,
              appUserID: String,
              completion: PostRequestResponseHandler?) {
        guard subscriberAttributes.count > 0 else {
            Logger.warn(Strings.attribution.empty_subscriber_attributes)
            completion?(ErrorCode.emptySubscriberAttributes)
            return
        }

        guard let appUserID = try? appUserID.escapedOrError() else {
            completion?(ErrorUtils.missingAppUserIDError())
            return
        }

        let path = "/subscribers/\(appUserID)/attributes"

        let attributesInBackendFormat = self.subscriberAttributesMarshaller
            .subscriberAttributesToDict(subscriberAttributes: subscriberAttributes)
        httpClient.performPOSTRequest(serially: true,
                                      path: path,
                                      requestBody: ["attributes": attributesInBackendFormat],
                                      headers: authHeaders) { statusCode, response, error in
            self.subscriberAttributeHandler.handleSubscriberAttributesResult(statusCode: statusCode,
                                                                             maybeResponse: response,
                                                                             maybeError: error,
                                                                             maybeCompletion: completion)
        }
    }

}
