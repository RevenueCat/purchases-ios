import Foundation

@objc(RCHealthCheck) public final class HealthCheck: NSObject, Sendable {
    public let offerings: [AppHealthResponse.AppHealthOffering]
    
    init(offerings: [AppHealthResponse.AppHealthOffering]) {
        self.offerings = offerings
    }
}
