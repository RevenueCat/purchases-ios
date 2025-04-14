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

                let productPayloads = payload.products.map { productCheck in
                    return PurchasesDiagnostics.ProductDiagnosticsPayload(
                        identifier: productCheck.identifier,
                        title: productCheck.title,
                        status: status(from: productCheck.status),
                        description: productCheck.description
                    )
                }

                return productPayloads
            }()

            let offerings: [PurchasesDiagnostics.OfferingDiagnosticsPayload] = {
                guard case let .offeringsProducts(payload) = self
                    .checks
                    .first(where: { $0.name == .products })?.details else {
                    return []
                }

                let offeringPayloads = payload.offerings.map { offeringCheck in
                    let status = self.convertOfferingStatus(offeringCheck.status)
                    return PurchasesDiagnostics.OfferingDiagnosticsPayload(
                        identifier: offeringCheck.identifier,
                        packages: offeringCheck.packages.map { self.createPackagePayload(from: $0) },
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

    func error(from check: HealthCheck) -> PurchasesDiagnostics.Error {
        switch check.name {
        case .apiKey: return .invalidAPIKey
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
            return PurchasesDiagnostics.ProductDiagnosticsPayload(
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

    private func createPackagePayload(from packageReport: PackageHealthReport)
        -> PurchasesDiagnostics.OfferingPackageDiagnosticsPayload {
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
