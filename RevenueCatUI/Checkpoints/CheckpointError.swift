//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointError.swift
//
//  Created by Rick van der Linden.
//

import Foundation
@_spi(Internal) import RevenueCat

enum CheckpointError: Error {

    case invalidIdentifier(String)
    case missingPresenter
    case operationAlreadyInProgress
    case noPresentationContext
    case presentationFailed

}

extension CheckpointError: CustomNSError {

    static var errorDomain: String {
        return ErrorCode.errorDomain
    }

    var errorCode: Int {
        switch self {
        case .invalidIdentifier, .missingPresenter, .noPresentationContext, .presentationFailed:
            return ErrorCode.configurationError.rawValue
        case .operationAlreadyInProgress:
            return ErrorCode.operationAlreadyInProgressForProductError.rawValue
        }
    }

    var errorUserInfo: [String: Any] {
        return [NSLocalizedDescriptionKey: self.errorDescription]
    }

    private var errorDescription: String {
        switch self {
        case .invalidIdentifier(let identifier):
            return "Checkpoint identifier '\(identifier)' is invalid. Identifiers must start with a letter, " +
                "contain only ASCII letters, numbers, underscores, and hyphens, and be no more than 100 characters."
        case .missingPresenter:
            return "Cannot present checkpoint UI: no presentation handler was supplied."
        case .operationAlreadyInProgress:
            return "Another checkpoint UI is already being presented."
        case .noPresentationContext:
            return "Unable to locate a view controller for checkpoint presentation."
        case .presentationFailed:
            return "Unable to present checkpoint UI."
        }
    }

}
