extension HealthReport {
    func validate() -> PurchasesDiagnostics.SDKHealthStatus {
        guard let firstFailedCheck = self.checks.first(where: { $0.status == .failed }) else {
            let warnings = self.checks.filter { $0.status == .warning }.map { error(from: $0) }
            
            return .healthy(warnings: warnings)
        }
        
        return .unhealthy(error(from: firstFailedCheck))
    }
    
    func error(from check: HealthCheck) -> PurchasesDiagnostics.Error {
        switch check.name {
        case .apiKey: return .invalidAPIKey
        case .sdkVersion: return .invalidSDKVersion
        case .bundleId:
            guard case let .bundleId(payload) = check.details else { return .invalidBundleId(nil) }
            
            return .invalidBundleId(.init(appBundleId: payload.appBundleId, sdkBundleId: payload.sdkBundleId))
        case .products:
            guard case let .products(payload) = check.details else {
                return .invalidProducts([])
            }
            
            let productPayloads = payload.products.map { productCheck in
                PurchasesDiagnostics.InvalidProductErrorPayload(
                    identifier: productCheck.identifier,
                    title: productCheck.title,
                    status: .init(rawValue: productCheck.status) ?? .unknown,
                    description: productCheck.description
                )
            }
            
            return .invalidProducts(productPayloads)
        case .offerings: return .noOfferings
        case .offeringsProducts:
            guard case let .offeringsProducts(payload) = check.details else {
                return .offeringConfiguration([])
            }
            
            let offeringPayloads = payload.offerings.map { offeringCheck in
                let status: PurchasesDiagnostics.SDKHealthCheckStatus = {
                    switch offeringCheck.status {
                    case .passed: .passed
                    case .failed: .failed
                    case .warning: .warning
                    default: .failed
                    }
                }()
                return PurchasesDiagnostics.OfferingConfigurationErrorPayload(
                    identifier: offeringCheck.identifier,
                    packages: offeringCheck.packages.map { packageCheck in
                        .init(
                            identifier: packageCheck.identifier,
                            title: packageCheck.title,
                            status: .init(rawValue: packageCheck.status) ?? .unknown,
                            description: packageCheck.description,
                            productIdentifier: packageCheck.productIdentifier,
                            productTitle: packageCheck.productTitle
                        )
                    },
                    status: status
                )
            }
            
            return .offeringConfiguration(offeringPayloads)
        }
    }
}
