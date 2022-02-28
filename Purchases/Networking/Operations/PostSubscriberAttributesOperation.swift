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
    private let responseHandler: SimpleResponseHandler?

    init(configuration: UserSpecificConfiguration,
         subscriberAttributes: SubscriberAttributeDict,
         completion: SimpleResponseHandler?,
         subscriberAttributesMarshaller: SubscriberAttributesMarshaller = SubscriberAttributesMarshaller(),
         subscriberAttributeHandler: SubscriberAttributeHandler = SubscriberAttributeHandler()) {
        self.configuration = configuration
        self.subscriberAttributes = subscriberAttributes
        self.responseHandler = completion
        self.subscriberAttributesMarshaller = subscriberAttributesMarshaller
        self.subscriberAttributeHandler = subscriberAttributeHandler

        super.init(configuration: configuration)
    }

    override func begin(completion: @escaping () -> Void) {
        post(completion: completion)
    }

    private func post(completion: @escaping () -> Void) {
        guard self.subscriberAttributes.count > 0 else {
            Logger.warn(Strings.attribution.empty_subscriber_attributes)
            self.responseHandler?(ErrorCode.emptySubscriberAttributes)
            completion()

            return
        }

        guard let appUserID = try? self.configuration.appUserID.escapedOrError() else {
            self.responseHandler?(ErrorUtils.missingAppUserIDError())
            completion()

            return
        }

        let attributesInBackendFormat = self.subscriberAttributesMarshaller
            .map(subscriberAttributes: self.subscriberAttributes)
        let request = HTTPRequest(method: .post(body: ["attributes": attributesInBackendFormat]),
                                  path: .postSubscriberAttributes(appUserID: appUserID))

        httpClient.perform(request, authHeaders: self.authHeaders) { statusCode, response, error in
            defer {
                completion()
            }

            guard let responseHandler = self.responseHandler else {
                return
            }

            self.subscriberAttributeHandler.handleSubscriberAttributesResult(statusCode: statusCode,
                                                                             response: response,
                                                                             error: error,
                                                                             completion: responseHandler)
        }
    }

}
