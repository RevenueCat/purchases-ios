//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  PaywallComponentLocalizationValidation.swift
//
//  Created by James Borthwick on 2024-09-02.

import Foundation

extension PaywallComponent {

    public func validateLocalizationIDs(using localizationDict: [String: String]) -> Bool {
        switch self {
        case .text(let textComponent):
            return validateLocalizationIDs(in: textComponent, using: localizationDict)
        case .image(let imageComponent):
            return validateLocalizationIDs(in: imageComponent, using: localizationDict)
        case .spacer(let spacerComponent):
            return validateLocalizationIDs(in: spacerComponent, using: localizationDict)
        case .stack(let stackComponent):
            return validateLocalizationIDs(in: stackComponent, using: localizationDict)
        case .linkButton(let linkButtonComponent):
            return validateLocalizationIDs(in: linkButtonComponent, using: localizationDict)
        }
    }

    private func validateLocalizationIDs(in object: Any, using localizationDict: [String: String]) -> Bool {
        let mirror = Mirror(reflecting: object)
        var isValid = true

        for child in mirror.children {
            if let label = child.label, label.hasSuffix("Lid") {
                if let localizationID = child.value as? String {
                    if localizationDict[localizationID] == nil {
                        print("Missing localization for ID: \(localizationID)")
                        isValid = false
                    }
                }
            } else if let value = child.value as? (any PaywallComponentBase) {
                // direct PaywallComponentBase types
                isValid = validateLocalizationIDs(in: value, using: localizationDict) && isValid
            } else if let components = child.value as? [PaywallComponent] {
                // PaywallComponent arrays
                for component in components {
                    isValid = component.validateLocalizationIDs(using: localizationDict) && isValid
                }
            }
        }
        return isValid
    }
}
