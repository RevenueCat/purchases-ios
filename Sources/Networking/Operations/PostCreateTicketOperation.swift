//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PostCreateTicketOperation.swift
//
//  Created by Rosie Watson 11/10/2025

import Foundation

class PostCreateTicketOperation: NetworkOperation {

    private let configuration: UserSpecificConfiguration
    private let customerEmail: String
    private let ticketDescription: String
    private let responseHandler: CreateTicketResponseHandler?

    typealias CreateTicketResponseHandler = (Result<CreateTicketResponse, BackendError>) -> Void

    init(configuration: UserSpecificConfiguration,
         customerEmail: String,
         ticketDescription: String,
         responseHandler: CreateTicketResponseHandler?) {
        self.customerEmail = customerEmail
        self.ticketDescription = ticketDescription
        self.configuration = configuration
        self.responseHandler = responseHandler

        super.init(configuration: configuration)
    }

    override func begin(completion: @escaping () -> Void) {
        self.post(completion: completion)
    }

    private func post(completion: @escaping () -> Void) {
        let appUserID = self.configuration.appUserID

        guard appUserID.isNotEmpty else {
            self.responseHandler?(.failure(.missingAppUserID()))
            completion()
            return
        }

        let body = Body(
            appUserID: appUserID,
            customerEmail: self.customerEmail,
            issueDescription: self.ticketDescription
        )
        let request = HTTPRequest(method: .post(body), path: .postCreateTicket)

        self.httpClient.perform(request) { (response: VerifiedHTTPResponse<CreateTicketResponse>.Result) in
            defer {
                completion()
            }

            self.responseHandler?(
                response
                    .map { $0.body }
                    .mapError(BackendError.networkError)
            )
        }
    }

}

// Restating inherited @unchecked Sendable from Foundation's Operation
extension PostCreateTicketOperation: @unchecked Sendable {}

private struct PostCreateTicketBody: HTTPRequestBody, Encodable {

    let appUserID: String
    let customerEmail: String
    let issueDescription: String

    enum CodingKeys: String, CodingKey {
        case appUserID = "app_user_id"
        case customerEmail = "customer_email"
        case issueDescription = "issue_description"
    }

}

private extension PostCreateTicketOperation {

    typealias Body = PostCreateTicketBody

}

struct CreateTicketResponse: HTTPResponseBody, Decodable {

    let sent: Bool

}
