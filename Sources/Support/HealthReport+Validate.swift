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
        case .bundleId: return createBundleIdError(from: check)
        case .products: return createProductsError(from: check)
        case .offerings: return .noOfferings
        case .offeringsProducts: return createOfferingsError(from: check)
        }
    }

    private func createBundleIdError(from check: HealthCheck) -> PurchasesDiagnostics.Error {
        guard case let .bundleId(payload) = check.details else {
            return .invalidBundleId(nil)
        }
        return .invalidBundleId(.init(appBundleId: payload.appBundleId, sdkBundleId: payload.sdkBundleId))
    }

    private func createProductsError(from check: HealthCheck) -> PurchasesDiagnostics.Error {
        guard case let .products(payload) = check.details else {
            return .invalidProducts([])
        }

        let productPayloads = payload.products.map { productCheck in
            return PurchasesDiagnostics.InvalidProductErrorPayload(
                identifier: productCheck.identifier,
                title: productCheck.title,
                status: status(from: productCheck.status),
                description: productCheck.description
            )
        }

        return .invalidProducts(productPayloads)
    }

    private func createOfferingsError(from check: HealthCheck) -> PurchasesDiagnostics.Error {
        guard case let .offeringsProducts(payload) = check.details else {
            return .offeringConfiguration([])
        }

        let offeringPayloads = payload.offerings.map { offeringCheck in
            let status = self.convertOfferingStatus(offeringCheck.status)
            return PurchasesDiagnostics.OfferingConfigurationErrorPayload(
                identifier: offeringCheck.identifier,
                packages: offeringCheck.packages.map { self.createPackagePayload(from: $0) },
                status: status
            )
        }

        return .offeringConfiguration(offeringPayloads)
    }

    private func convertOfferingStatus(_ status: HealthCheckStatus) -> PurchasesDiagnostics.SDKHealthCheckStatus {
        switch status {
        case .passed: return .passed
        case .failed: return .failed
        case .warning: return .warning
        default: return .failed
        }
    }

    private func createPackagePayload(from packageReport: PackageHealthReport)
        -> PurchasesDiagnostics.OfferingConfigurationErrorPayloadPackage {
        .init(
            identifier: packageReport.identifier,
            title: packageReport.title,
            status: status(from: packageReport.status),
            description: packageReport.description,
            productIdentifier: packageReport.productIdentifier,
            productTitle: packageReport.productTitle
        )
    }

    private func status(from productCheckStatus: ProductStatus) -> PurchasesDiagnostics.ProductStatus {
        switch productCheckStatus {
        case .valid: .valid
        case .couldNotCheck: .couldNotCheck
        case .notFound: .notFound
        case .actionInProgress: .actionInProgress
        case .needsAction: .needsAction
        case .unknown: .unknown
        }
    }
}
