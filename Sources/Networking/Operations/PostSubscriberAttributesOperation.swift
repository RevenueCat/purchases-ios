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

    private let configuration: UserSpecificConfiguration
    private let subscriberAttributes: SubscriberAttribute.Dictionary
    private let responseHandler: CustomerAPI.SimpleResponseHandler?

    init(configuration: UserSpecificConfiguration,
         subscriberAttributes: SubscriberAttribute.Dictionary,
         completion: CustomerAPI.SimpleResponseHandler?) {
        self.configuration = configuration
        self.subscriberAttributes = subscriberAttributes
        self.responseHandler = completion

        super.init(configuration: configuration)
    }

    override func begin(completion: @escaping () -> Void) {
        post(completion: completion)
    }

    private func post(completion: @escaping () -> Void) {
        guard self.subscriberAttributes.count > 0 else {
            Logger.warn(Strings.attribution.empty_subscriber_attributes)
            self.responseHandler?(.emptySubscriberAttributes())

            return
        }

        let appUserID = self.configuration.appUserID

        guard appUserID.isNotEmpty else {
            self.responseHandler?(.missingAppUserID())
            completion()

            return
        }

        do {
            let request = HTTPRequest(method: .post(try Body(self.subscriberAttributes)),
                                      path: .postSubscriberAttributes(appUserID: appUserID))

            self.httpClient.perform(request) { (response: VerifiedHTTPResponse<HTTPEmptyResponseBody>.Result) in
                defer {
                    completion()
                }

                self.responseHandler?(response.error.map(BackendError.networkError))
            }
        } catch {
            // TODO: log error

            self.responseHandler?(.networkError(
                .unableToCreateRequest(.postSubscriberAttributes(appUserID: appUserID))
            ))
        }
    }

}

extension PostSubscriberAttributesOperation {

    private struct Body: Encodable {

        let attributes: AnyCodable

        init(_ attributes: SubscriberAttribute.Dictionary) throws {
            self.attributes = try AnyCodable(
                SubscriberAttribute.map(subscriberAttributes: attributes)
            )
        }

    }

}
