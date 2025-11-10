//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CreateTicketAPI.swift
//
//  Created by Rosie Watson on 11/10/2025
//

import Foundation

class CreateTicketAPI {

    typealias CreateTicketResponseHandler = PostCreateTicketOperation.CreateTicketResponseHandler

    private let backendConfig: BackendConfiguration

    init(backendConfig: BackendConfiguration) {
        self.backendConfig = backendConfig
    }

    func postCreateTicket(appUserID: String,
                          customerEmail: String,
                          ticketDescription: String,
                          completion: @escaping CreateTicketResponseHandler) {
        let config = NetworkOperation.UserSpecificConfiguration(httpClient: self.backendConfig.httpClient,
                                                                appUserID: appUserID)

        let operation = PostCreateTicketOperation(configuration: config,
                                                  customerEmail: customerEmail,
                                                  ticketDescription: ticketDescription,
                                                  responseHandler: completion)

        self.backendConfig.operationQueue.addOperation(operation)
    }

}
