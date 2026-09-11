//
//  WorkflowsResponse+OfferingIdentifier.swift
//  RevenueCat
//
//  Created by Rick van der Linden.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import Foundation

extension WorkflowStep {

    /// The offering this step presents, from `param_values.offering.identifier`, or from the legacy
    /// flat `param_values.offering_identifier` value when the nested value is absent.
    var offeringIdentifier: String? {
        let nestedIdentifier: AnyDecodable?
        if case let .object(offering)? = self.paramValues["offering"] {
            nestedIdentifier = offering["identifier"]
        } else {
            nestedIdentifier = nil
        }

        guard case let .string(identifier)? = nestedIdentifier ?? self.paramValues["offering_identifier"],
              identifier.isNotEmpty else {
            return nil
        }
        return identifier
    }

}

extension PublishedWorkflow {

    /// The offering a step presents: the step's own offering, or the offering configured on its screen.
    @_spi(Internal) public func offeringIdentifier(for step: WorkflowStep) -> String? {
        return step.offeringIdentifier ?? step.screenId.flatMap { self.screens[$0]?.offeringIdentifier }
    }

}
