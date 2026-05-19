//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  InputSingleChoiceContext.swift

import Foundation

#if !os(tvOS)

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class InputSingleChoiceContext: ObservableObject {

    let fieldId: String
    @Published var selectedOptionId: String?

    init(fieldId: String) {
        self.fieldId = fieldId
    }

}

#endif
