//
//  ResumeAction.swift
//  RevenueCat
//
//  Created by Jacob Zivan Rakidzich on 11/5/25.
//

import Foundation

/// A container for a function that is invoked to resume or cancel a flow
public struct ResumeAction: Sendable {
    private let action: @Sendable (Bool) -> Void

    /// Create a ResumeAction
    /// - Parameter action: The handler that will be invoked later
    public init(action: @escaping @Sendable (Bool) -> Void) {
        self.action = action
    }

    /// A function that is invoked to resume or cancel a flow
    /// - Parameter shouldProceed: true if a flow should continue, false if not.
    @MainActor
    public func resume(shouldProceed: Bool) {
        action(shouldProceed)
    }
}

public extension ResumeAction {

    /// A function that is invoked to resume or cancel a flow
    /// - Parameter shouldProceed: true if a flow should continue, false if not.
    @MainActor
    func callAsFunction(shouldProceed: Bool = true) {
        resume(shouldProceed: shouldProceed)
    }
}
