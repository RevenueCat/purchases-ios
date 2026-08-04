//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointWorkflow.swift
//
//  Created by Rick van der Linden.
//

import Foundation

struct CheckpointWorkflow: Decodable {

    let id: String
    let presentation: DemoWorkflowPresentation
    let pages: [CheckpointWorkflowPage]

}

struct DemoWorkflowPresentation: Decodable {
    let dismissible: Bool
}

struct CheckpointWorkflowPage: Decodable {
    let components: [CheckpointWorkflowComponent]
    let actions: [CheckpointWorkflowAction]
}

struct CheckpointWorkflowComponent: Decodable {

    enum Kind: String, Decodable {
        case image
        case title
        case body
        case feature
    }

    let type: Kind
    let text: String?
    let systemName: String?

}

struct CheckpointWorkflowAction: Decodable {

    enum Kind: String, Decodable {
        case next
        case previous
        case purchase
        case restore
        case dismiss
        case complete
        case error
    }

    enum Style: String, Decodable {
        case primary
        case secondary
        case destructive
    }

    let title: String
    let type: Kind
    let style: Style

}
