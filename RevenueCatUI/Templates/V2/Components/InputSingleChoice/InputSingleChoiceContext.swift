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

import Combine
import Foundation

#if !os(tvOS)

/// Shared state for an `InputSingleChoiceComponent` and its `InputOptionComponent` children.
///
/// `InputSingleChoiceComponentView` creates one instance via `@StateObject` and injects it into
/// the environment. Each child `InputOptionComponentView` reads it via `@EnvironmentObject` to
/// determine whether it is the currently selected option and to update the selection on tap.
///
/// The `fieldId` identifies which form field this selection belongs to. The backend uses the
/// `componentId` that fires the workflow trigger to identify the chosen value, so `selectedOptionId`
/// is only needed client-side to drive the `.selected` visual state on child components.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
final class InputSingleChoiceContext: ObservableObject {

    /// Identifies the form field this group of options belongs to.
    let fieldId: String

    /// The `optionId` of the currently selected option, or `nil` if none is selected.
    @Published var selectedOptionId: String?

    init(fieldId: String) {
        self.fieldId = fieldId
    }

}

#endif
