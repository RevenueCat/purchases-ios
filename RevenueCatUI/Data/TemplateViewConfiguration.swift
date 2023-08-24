//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  TemplateViewConfiguration.swift
//
//  Created by Nacho Soto on 7/17/23.

import Foundation
import RevenueCat

/// The processed data necessary to render a `TemplateViewType`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
struct TemplateViewConfiguration {

    let mode: PaywallViewMode
    let packages: PackageConfiguration
    let configuration: PaywallData.Configuration
    let colors: PaywallData.Configuration.Colors
    let fonts: PaywallFontProvider
    let assetBaseURL: URL

}

// MARK: - Packages

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension TemplateViewConfiguration {

    /// A `Package` with its processed localized strings.
    struct Package: Equatable {

        let content: RevenueCat.Package
        let localization: ProcessedLocalizedConfiguration
        let currentlySubscribed: Bool
        let discountRelativeToMostExpensivePerMonth: Double?

    }

    /// Whether a template displays 1 or multiple packages.
    enum PackageSetting: Equatable {

        case single
        case multiple

    }

    /// Describes the possible displayed packages in a paywall.
    /// See `create(with:filter:setting:)` for how to create these.
    enum PackageConfiguration: Equatable {

        case single(Package)
        case multiple(first: Package, default: Package, all: [Package])

    }

}

// MARK: - Properties

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension TemplateViewConfiguration.PackageConfiguration {

    /// Returns a single package, useful for templates that expect a single package.
    var single: TemplateViewConfiguration.Package {
        switch self {
        case let .single(package):
            return package
        case let .multiple(first, _, _):
            return first
        }
    }

    /// Returns all packages, useful for templates that expect multiple packages.
    var all: [TemplateViewConfiguration.Package] {
        switch self {
        case let .single(package):
            return [package]
        case let .multiple(_, _, packages):
            return packages
        }
    }

    /// Returns the package to be selected by default.
    var `default`: TemplateViewConfiguration.Package {
        switch self {
        case let .single(package):
            return package
        case let .multiple(_, defaultPackage, _):
            return defaultPackage
        }
    }

}

// MARK: - Creation

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension TemplateViewConfiguration.PackageConfiguration {

    /// Creates a `PackageConfiguration` based on `setting`.
    /// - Throws: `TemplateError`
    // swiftlint:disable:next function_parameter_count
    static func create(
        with packages: [RevenueCat.Package],
        activelySubscribedProductIdentifiers: Set<String>,
        filter: [String],
        default: String?,
        localization: PaywallData.LocalizedConfiguration,
        setting: TemplateViewConfiguration.PackageSetting,
        locale: Locale = .current
    ) throws -> Self {
        guard !packages.isEmpty else { throw TemplateError.noPackages }
        guard !filter.isEmpty else { throw TemplateError.emptyPackageList }

        let filtered = TemplateViewConfiguration.filter(packages: packages, with: filter)
        let mostExpensivePricePerMonth = Self.mostExpensivePricePerMonth(in: filtered)

        let filteredPackages = filtered
            .map { package in
                TemplateViewConfiguration.Package(
                    content: package,
                    localization: localization.processVariables(with: package, locale: locale),
                    currentlySubscribed: activelySubscribedProductIdentifiers.contains(
                        package.storeProduct.productIdentifier
                    ),
                    discountRelativeToMostExpensivePerMonth: Self.discount(
                        from: package.storeProduct.pricePerMonth?.doubleValue,
                        relativeTo: mostExpensivePricePerMonth
                    )
                )
            }

        guard let firstPackage = filteredPackages.first else {
            throw TemplateError.couldNotFindAnyPackages(expectedTypes: filter)
        }

        switch setting {
        case .single:
            return .single(firstPackage)
        case .multiple:
            let defaultPackage = filteredPackages
                .first { $0.content.identifier == `default` }
                ?? firstPackage

            return .multiple(first: firstPackage,
                             default: defaultPackage,
                             all: filteredPackages)
        }
    }

    private static func mostExpensivePricePerMonth(in packages: [Package]) -> Double? {
        return packages
            .lazy
            .map(\.storeProduct)
            .compactMap { product in
                product.pricePerMonth.map {
                    return (
                        product: product,
                        pricePerMonth: $0
                    )
                }
            }
            .max { productA, productB in
                return productA.pricePerMonth.doubleValue < productB.pricePerMonth.doubleValue
            }
            .map(\.pricePerMonth.doubleValue)
    }

    private static func discount(from pricePerMonth: Double?, relativeTo mostExpensive: Double?) -> Double? {
        guard let pricePerMonth, let mostExpensive else { return nil }
        guard pricePerMonth < mostExpensive else { return nil }

        return (mostExpensive - pricePerMonth) / mostExpensive
    }

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, *)
extension TemplateViewConfiguration {

    /// Filters `packages`, extracting only the values corresponding to `identifiers`.
    static func filter(packages: [RevenueCat.Package], with identifiers: [String]) -> [RevenueCat.Package] {
        let map = Dictionary(grouping: packages) { $0.identifier }

        return identifiers.compactMap { identifier in
            if let packages = map[identifier] {
                switch packages.count {
                case 0:
                    // This isn't actually possible because of `Dictionary(grouping:by:)
                    return nil
                case 1:
                    return packages.first
                default:
                    Logger.warning(Strings.found_multiple_packages_of_same_identifier(identifier))
                    return packages.first
                }
            } else {
                return nil
            }
        }
    }

}
