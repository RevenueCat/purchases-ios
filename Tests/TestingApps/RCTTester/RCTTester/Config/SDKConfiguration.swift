//
//  SDKConfiguration.swift
//  RCTTester
//

import Foundation

/// Configuration for how the SDK should be set up
struct SDKConfiguration: Codable, Equatable {

    /// The RevenueCat API key
    var apiKey: String

    /// Which StoreKit version to use
    var storeKitVersion: StoreKitVersion

    /// Who completes purchases
    var purchasesAreCompletedBy: PurchasesCompletedBy

    /// How purchases are made when using observer mode (.myApp)
    /// Only relevant when `purchasesAreCompletedBy` is `.myApp`
    var purchaseLogic: PurchaseLogic

    // MARK: - Nested Types

    enum StoreKitVersion: String, Codable, CaseIterable, Identifiable {
        case storeKit1
        case storeKit2

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .storeKit1: return "StoreKit 1"
            case .storeKit2: return "StoreKit 2"
            }
        }
    }

    enum PurchasesCompletedBy: String, Codable, CaseIterable, Identifiable {
        case revenueCat
        case myApp

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .revenueCat: return ".revenueCat"
            case .myApp: return ".myApp"
            }
        }
    }

    enum PurchaseLogic: String, Codable, CaseIterable, Identifiable {
        case throughRevenueCat
        case usingStoreKitDirectly

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .throughRevenueCat: return "Use RevenueCat's purchase methods"
            case .usingStoreKitDirectly: return "Use StoreKit APIs directly"
            }
        }
    }

    // MARK: - Defaults

    static var `default`: SDKConfiguration {
        SDKConfiguration(
            apiKey: Constants.apiKey,
            storeKitVersion: .storeKit2,
            purchasesAreCompletedBy: .revenueCat,
            purchaseLogic: .throughRevenueCat
        )
    }

    // MARK: - Persistence

    private static let userDefaultsKey = "com.revenuecat.rcttester.sdkConfiguration"

    /// Loads the configuration from UserDefaults, or returns default if none exists
    static func load() -> SDKConfiguration {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let configuration = try? JSONDecoder().decode(SDKConfiguration.self, from: data) else {
            return .default
        }
        return configuration
    }

    /// Saves the configuration to UserDefaults
    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
    }
}
