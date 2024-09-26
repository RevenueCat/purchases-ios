import RevenueCat

/// Typealias for handler for Customer center actions
public typealias CustomerCenterActionHandler = @MainActor @Sendable (CustomerCenterAction) -> Void

/// Represents an event the customer may perform during the Customer Center flow
public enum CustomerCenterAction {

    /// Starting the restoration process
    case restoreStarted
    /// Restore errored out
    /// - Parameter error: The error that occurred
    case restoreFailed(_ error: Error)
    /// Restore completed successfully
    /// - Parameter customerInfo: The customer info after the restore
    case restoreCompleted(_ customerInfo: CustomerInfo)
    /// Going to display manage subscription page, whether for cancellation or changing plans.
    case showingManageSubscriptions
    /// Starting refund request process
    /// - Parameter productId: The product id for the refund request
    case refundRequestStarted(_ productId: String)
    /// Refund request process finished, with result provided.
    /// - Parameter refundRequestStatus: The status of the refund request
    case refundRequestCompleted(_ refundRequestStatus: RefundRequestStatus)
    /// An option of the feedback survey has been selected
    /// - Parameter feedbackSurveyOptionId: The id of the feedback survey option selected
    case feedbackSurveyCompleted(_ feedbackSurveyOptionId: String)

}
