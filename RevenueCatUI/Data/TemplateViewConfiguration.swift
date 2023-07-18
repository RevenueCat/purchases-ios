//
//  TemplateViewConfiguration.swift
//  
//
//  Created by Nacho Soto on 7/17/23.
//

import Foundation
import RevenueCat

/// The processed data necessary to render a `TemplateViewType`.
@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
struct TemplateViewConfiguration {

    let mode: PaywallViewMode
    let packages: PackageConfiguration
    let configuration: PaywallData.Configuration
    let colors: PaywallData.Configuration.Colors
    let imageURLs: [URL]

}

// MARK: - Packages

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
extension TemplateViewConfiguration {

    /// A `Package` with its processed localized strings.
    struct Package {

        let content: RevenueCat.Package
        let localization: ProcessedLocalizedConfiguration

    }

    /// Whether a template displays 1 or multiple packages.
    enum PackageSetting {

        case single
        case multiple

    }

    /// Describes the possible displayed packages in a paywall.
    /// See `create(with:filter:setting:)` for how to create these.
    enum PackageConfiguration {

        case single(Package)
        case multiple([Package])

    }

}

// MARK: - Properties

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
extension TemplateViewConfiguration.PackageConfiguration {

    /// Returns a single package, useful for templates that expect a single package.
    var single: TemplateViewConfiguration.Package {
        switch self {
        case let .single(package):
            return package
        case let .multiple(packages):
            guard let package = packages.first else {
                // `create()` makes this impossible.
                fatalError("Unexpectedly found no packages in `PackageConfiguration.multiple`")
            }

            return package
        }
    }

    /// Returns all packages, useful for templates that expect multiple packages
    var all: [TemplateViewConfiguration.Package] {
        switch self {
        case let .single(package):
            return [package]
        case let .multiple(packages):
            return packages
        }
    }

}

// MARK: - Creation

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
extension TemplateViewConfiguration.PackageConfiguration {

    /// Creates a `PackageConfiguration` based on `setting`.
    /// - Throws: `TemplateError`
    static func create(
        with packages: [RevenueCat.Package],
        filter: [PackageType],
        localization: PaywallData.LocalizedConfiguration,
        setting: TemplateViewConfiguration.PackageSetting
    ) throws -> Self {
        guard !packages.isEmpty else { throw TemplateError.noPackages }
        guard !filter.isEmpty else { throw TemplateError.emptyPackageList }

        let filtered = TemplateViewConfiguration
            .filter(packages: packages, with: filter)
            .map { package in
                TemplateViewConfiguration.Package(
                    content: package,
                    localization: localization.processVariables(with: package))
            }

        guard let firstPackage = filtered.first else {
            throw TemplateError.couldNotFindAnyPackages(expectedTypes: filter)
        }

        switch setting {
        case .single:
            return .single(firstPackage)
        case .multiple:
            return .multiple(filtered)
        }
    }

}

@available(iOS 16.0, macOS 13.0, tvOS 16.0, *)
extension TemplateViewConfiguration {

    /// Filters `packages`, extracting only the values corresponding to `list`.
    static func filter(packages: [RevenueCat.Package], with list: [PackageType]) -> [RevenueCat.Package] {
        // Only subscriptions are supported at the moment
        let subscriptions = packages.filter { $0.storeProduct.productCategory == .subscription }
        let map = Dictionary(grouping: subscriptions) { $0.packageType }

        return list.compactMap { type in
            if let packages = map[type] {
                switch packages.count {
                case 0:
                    // This isn't actually possible because of `Dictionary(grouping:by:)
                    return nil
                case 1:
                    return packages.first
                default:
                    Logger.warning("Found multiple \(type) packages. Will use the first one.")
                    return packages.first
                }
            } else {
                Logger.warning("Couldn't find '\(type)'")
                return nil
            }
        }
    }

}
