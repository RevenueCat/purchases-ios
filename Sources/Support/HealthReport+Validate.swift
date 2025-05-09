//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  HealthReport+Validate.swift
//
//  Created by Pol Piella on 4/10/25.

#if DEBUG
extension HealthReport {
    func validate() -> PurchasesDiagnostics.SDKHealthReport {
        guard let firstFailedCheck = self.checks.first(where: { $0.status == .failed }) else {
            let warnings = self.checks.filter { $0.status == .warning }.map { error(from: $0) }
            let products: [PurchasesDiagnostics.ProductDiagnosticsPayload] = {
                guard case let .products(payload) = self
                    .checks
                    .first(where: { $0.name == .products })?.details else {
                    return []
                }

                let productPayloads = payload.products.map(createProductPayload(from:))

                return productPayloads
            }()

            let offerings: [PurchasesDiagnostics.OfferingDiagnosticsPayload] = {
                guard case let .offeringsProducts(payload) = self
                    .checks
                    .first(where: { $0.name == .offeringsProducts })?.details else {
                    return []
                }

                let offeringPayloads = payload.offerings.map { offeringCheck in
                    let status = self.convertOfferingStatus(offeringCheck.status)
                    return PurchasesDiagnostics.OfferingDiagnosticsPayload(
                        identifier: offeringCheck.identifier,
                        packages: offeringCheck.packages.map(createPackagePayload(from:)),
                        status: status
                    )
                }

                return offeringPayloads
            }()

            return .init(
                status: .healthy(warnings: warnings),
                projectId: self.projectId,
                appId: self.appId,
                products: products,
                offerings: offerings
            )
        }

        return .init(
            status: .unhealthy(error(from: firstFailedCheck)),
            projectId: self.projectId,
            appId: self.appId
        )
    }

    func error(from check: HealthCheck) -> PurchasesDiagnostics.SDKHealthError {
        switch check.name {
        case .apiKey: return .invalidAPIKey
        case .bundleId: return createBundleIdError(from: check)
        case .products: return createProductsError(from: check)
        case .offerings: return .noOfferings
        case .offeringsProducts: return createOfferingsError(from: check)
        }
    }

    private func createBundleIdError(from check: HealthCheck) -> PurchasesDiagnostics.SDKHealthError {
        guard case let .bundleId(payload) = check.details else {
            return .invalidBundleId(nil)
        }
        return .invalidBundleId(.init(appBundleId: payload.appBundleId, sdkBundleId: payload.sdkBundleId))
    }

    private func createProductsError(from check: HealthCheck) -> PurchasesDiagnostics.SDKHealthError {
        guard case let .products(payload) = check.details else {
            return .invalidProducts([])
        }

        return .invalidProducts(payload.products.map(createProductPayload))
    }

    private func createOfferingsError(from check: HealthCheck) -> PurchasesDiagnostics.SDKHealthError {
        guard case let .offeringsProducts(payload) = check.details else {
            return .offeringConfiguration([])
        }

        let offeringPayloads = payload.offerings.map { offeringCheck in
            let status = self.convertOfferingStatus(offeringCheck.status)
            return PurchasesDiagnostics.OfferingDiagnosticsPayload(
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

    private func createProductPayload(
        from productReport: ProductHealthReport
    ) -> PurchasesDiagnostics.ProductDiagnosticsPayload {
        .init(
            identifier: productReport.identifier,
            title: productReport.title,
            status: status(from: productReport.status),
            description: description(
                from: productReport.status,
                identifier: productReport.identifier,
                description: productReport.description
            )
        )
    }

    private func createPackagePayload(from packageReport: PackageHealthReport)
        -> PurchasesDiagnostics.OfferingPackageDiagnosticsPayload {
        .init(
            identifier: packageReport.identifier,
            title: packageReport.title,
            status: status(from: packageReport.status),
            description: description(
                from: packageReport.status,
                identifier: packageReport.productIdentifier,
                description: packageReport.description
            ),
            productIdentifier: packageReport.productIdentifier,
            productTitle: packageReport.productTitle
        )
    }

    private func description(
        from status: ProductStatus,
        identifier: String,
        description: String
    ) -> String {
        switch status {
        case .valid:
            return "Available for production purchases."
        case .couldNotCheck:
            return description
        case .notFound:
            return """
                Product not found in App Store Connect. You need to create a product with identifier: \
                '\(identifier)' in App Store Connect to use it for production purchases.
                """
        case .actionInProgress:
            return """
                Some process is ongoing and needs to be completed before using this product in production purchases, \
                by Apple (state: \(description)). \
                You can still make test purchases with the RevenueCat SDK, but you will need to \
                wait for the state to change before you can make production purchases.
                """
        case .needsAction:
            return """
                This product's status (\(description)) requires you to take action in App Store Connect \
                before using it in production purchases.
                """
        case .unknown:
            return """
                We could not check the status of your product using the App Store Connect API. \
                Please check the app's credentials in the dashboard and try again.
                """
        }
    }

    private func status(from productCheckStatus: ProductStatus) -> PurchasesDiagnostics.ProductStatus {
        switch productCheckStatus {
        case .valid: return .valid
        case .couldNotCheck: return .couldNotCheck
        case .notFound: return .notFound
        case .actionInProgress: return .actionInProgress
        case .needsAction: return .needsAction
        case .unknown: return .unknown
        }
    }
}
#endif
