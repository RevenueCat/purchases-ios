//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  WorkflowStep+ExperimentData.swift
//
//  Created by Rosie Watson on 10/30/26.

import Foundation

extension WorkflowStep {

    /// The experiment this step belongs to, or `nil` when it is not in one or the workflow has no blob ref to
    /// attribute it to.
    @_spi(Internal) public func experimentData(workflowBlobRef: String?) -> WorkflowEvent.ExperimentData? {
        guard let experimentId = self.experimentId,
              let experimentVariant = self.experimentVariant,
              workflowBlobRef != nil else {
            return nil
        }

        return .init(experimentId: experimentId, experimentVariant: experimentVariant)
    }

}
