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

// swiftlint:disable nesting force_unwrapping

/// The processed data necessary to render a `TemplateViewType`.
@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
struct TemplateViewConfiguration {

    let mode: PaywallViewMode
    let packages: PackageConfiguration
    let configuration: PaywallData.Configuration
    let colors: PaywallData.Configuration.Colors
    let colorsByTier: [PaywallData.Tier: PaywallData.Configuration.Colors]
    let fonts: PaywallFontProvider
    let assetBaseURL: URL
    let showZeroDecimalPlacePrices: Bool

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension TemplateViewConfiguration {

    func colors(for tier: PaywallData.Tier) -> PaywallData.Configuration.Colors {
        return self.colorsByTier[tier] ?? self.colors
    }

}

// MARK: - Packages

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension TemplateViewConfiguration {

    /// A `Package` with its processed localized strings.
    struct Package: Equatable {

        let content: RevenueCat.Package
        let localization: ProcessedLocalizedConfiguration
        let currentlySubscribed: Bool
        let discountRelativeToMostExpensivePerMonth: Double?

    }

    /// Describes the possible displayed packages in a paywall.
    /// See `create(with:filter:setting:)` for how to create these.
    enum PackageConfiguration: Equatable {

        struct MultiPackage: Equatable {
            var first: Package
            var `default`: Package
            var all: [Package]
        }

        case single(Package)
        case multiple(MultiPackage)
        case multiTier(
            firstTier: PaywallData.Tier,
            all: [PaywallData.Tier: MultiPackage],
            tierNames: [PaywallData.Tier: String]
        )

    }

}

// MARK: - Properties

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension TemplateViewConfiguration.PackageConfiguration {

    /// Returns a single package, useful for templates that expect a single package.
    var single: TemplateViewConfiguration.Package {
        switch self {
        case let .single(package):
            return package
        case let .multiple(data):
            return data.first
        case let .multiTier(firstTier, all, _):
            return all[firstTier]!.first
        }
    }

    var multiTier: (
        firstTier: PaywallData.Tier,
        all: [PaywallData.Tier: MultiPackage],
        tierNames: [PaywallData.Tier: String]
    )? {
        switch self {
        case .single: return nil
        case .multiple: return nil
        case let .multiTier(first, all, names): return (first, all, names)
        }
    }

    /// Returns all packages, useful for templates that expect multiple packages.
    var all: [TemplateViewConfiguration.Package] {
        switch self {
        case let .single(package):
            return [package]
        case let .multiple(data):
            return data.all
        case let .multiTier(_, allTiers, _):
            return allTiers
                .flatMap { $0.value.all }
        }
    }

    /// Returns the package to be selected by default.
    var `default`: TemplateViewConfiguration.Package {
        switch self {
        case let .single(package):
            return package
        case let .multiple(data):
            return data.default
        case let .multiTier(firstTier, allTiers, _):
            return allTiers[firstTier]!.default
        }
    }

}

// MARK: - Creation

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension TemplateViewConfiguration.PackageConfiguration {

    private enum Parameters {

        case singleTier(
            filter: [String],
            default: String?,
            localization: PaywallData.LocalizedConfiguration,
            multiPackage: Bool
        )
        case multiTier(
            tiers: [PaywallData.Tier],
            localization: [String: PaywallData.LocalizedConfiguration]
        )

    }

    // swiftlint:disable:next function_parameter_count
    static func create(
        with packages: [RevenueCat.Package],
        activelySubscribedProductIdentifiers: Set<String>,
        filter: [String],
        default: String?,
        localization: PaywallData.LocalizedConfiguration?,
        localizationByTier: [String: PaywallData.LocalizedConfiguration]?,
        tiers: [PaywallData.Tier],
        setting: TemplatePackageSetting,
        locale: Locale = .current,
        showZeroDecimalPlacePrices: Bool = false
    ) throws -> Self {
        let parameters: Parameters

        switch setting.tierSetting {
        case .single:
            guard !packages.isEmpty else { throw TemplateError.noPackages }
            guard !filter.isEmpty else { throw TemplateError.emptyPackageList }
            guard let localization else { throw TemplateError.noLocalization }

            parameters = .singleTier(
                filter: filter,
                default: `default`,
                localization: localization,
                multiPackage: setting == .multiple
            )

        case .multiple:
            guard let localizationByTier else { throw TemplateError.noLocalization }

            parameters = .multiTier(tiers: tiers, localization: localizationByTier)
        }

        return try Self.create(
            with: packages,
            activelySubscribedProductIdentifiers: activelySubscribedProductIdentifiers,
            parameters: parameters,
            locale: locale,
            showZeroDecimalPlacePrices: showZeroDecimalPlacePrices
        )
    }

    /// Creates a `PackageConfiguration` based on `setting`.
    /// - Throws: `TemplateError`
    // swiftlint:disable:next function_body_length
    private static func create(
        with packages: [RevenueCat.Package],
        activelySubscribedProductIdentifiers: Set<String>,
        parameters: Parameters,
        locale: Locale,
        showZeroDecimalPlacePrices: Bool
    ) throws -> Self {
        switch parameters {
        case let .singleTier(filter, `default`, localization, multiPackage):
            let filteredPackages = Self.processPackages(
                from: packages,
                filter: filter,
                activelySubscribedProductIdentifiers: activelySubscribedProductIdentifiers,
                localization: localization,
                locale: locale,
                showZeroDecimalPlacePrices: showZeroDecimalPlacePrices
            )

            guard let firstPackage = filteredPackages.first else {
                throw TemplateError.couldNotFindAnyPackages(expectedTypes: filter)
            }

            if multiPackage {
                let defaultPackage = filteredPackages
                    .first { $0.content.identifier == `default` }
                ?? firstPackage

                return .multiple(.init(
                    first: firstPackage,
                    default: defaultPackage,
                    all: filteredPackages
                ))
            } else {
                return .single(firstPackage)
            }

        case let .multiTier(tiers, localization):
            let filteredTiers: [(PaywallData.Tier, (package: MultiPackage, tierName: String))] =
            try tiers.compactMap { tier in
                guard let localization = localization[tier.id] else {
                    throw TemplateError.missingLocalization(tier)
                }

                let tierName = localization.tierName ?? ""

                let filteredPackages = Self.processPackages(
                    from: packages,
                    filter: tier.packages,
                    activelySubscribedProductIdentifiers: activelySubscribedProductIdentifiers,
                    localization: localization,
                    locale: locale,
                    showZeroDecimalPlacePrices: showZeroDecimalPlacePrices
                )

                guard let firstPackage = filteredPackages.first else {
                    Logger.error(Strings.tier_has_no_available_products_for_paywall(tierName))
                    return nil
                }
                let defaultPackage = filteredPackages
                    .first { $0.content.identifier == tier.defaultPackage }
                ?? firstPackage

                return (
                    tier,
                    (
                        MultiPackage(
                            first: firstPackage,
                            default: defaultPackage,
                            all: filteredPackages
                        ),
                        tierName
                    )
                )
            }

            guard let (firstTier, _) = filteredTiers.first else {
                throw TemplateError.noTiers
            }

            let packagesAndTierNamesByTier: [PaywallData.Tier: (package: MultiPackage, tierName: String)] = Dictionary(
                filteredTiers,
                uniquingKeysWith: { _, new in new }
            )

            return .multiTier(
                firstTier: firstTier,
                all: packagesAndTierNamesByTier.mapValues { $0.package },
                tierNames: packagesAndTierNamesByTier.mapValues { $0.tierName }
            )
        }
    }

    // swiftlint:disable:next function_parameter_count
    private static func processPackages(
        from packages: [RevenueCat.Package],
        filter: [String],
        activelySubscribedProductIdentifiers: Set<String>,
        localization: PaywallData.LocalizedConfiguration,
        locale: Locale,
        showZeroDecimalPlacePrices: Bool
    ) -> [TemplateViewConfiguration.Package] {
        let filtered = TemplateViewConfiguration.filter(packages: packages, with: filter)
        let mostExpensivePricePerMonth = Self.mostExpensivePricePerMonth(in: filtered)

        return filtered
            .map { package in
                let discount = Self.discount(
                    from: package.storeProduct.pricePerMonth?.doubleValue,
                    relativeTo: mostExpensivePricePerMonth
                )

                return .init(
                    content: package,
                    localization: localization.processVariables(
                        with: package,
                        context: .init(discountRelativeToMostExpensivePerMonth: discount,
                                       showZeroDecimalPlacePrices: showZeroDecimalPlacePrices),
                        locale: locale
                    ),
                    currentlySubscribed: activelySubscribedProductIdentifiers.contains(
                        package.storeProduct.productIdentifier
                    ),
                    discountRelativeToMostExpensivePerMonth: discount
                )
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

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
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
