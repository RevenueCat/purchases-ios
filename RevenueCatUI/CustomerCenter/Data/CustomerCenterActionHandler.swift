import Foundation
import RevenueCat

@objc
public protocol CustomerCenterActionHandler {
    @objc optional func purchaseCompleted(_ customerInfo: CustomerInfo)
    @objc optional func restoreStarted()
    @objc optional func restoreCompleted(_ customerInfo: CustomerInfo)
}
