//
// Created by Andrés Boedo on 6/18/21.
// Copyright (c) 2021 Purchases. All rights reserved.
//

import Foundation
import StoreKit

@objc(RCPackageType) enum PackageType: Int {
    /// A package that was defined with a custom identifier.
    case unknown = -2,
        /// A package that was defined with a custom identifier.
         custom,
        /// A package configured with the predefined lifetime identifier.
         lifetime,
        /// A package configured with the predefined annual identifier.
         annual,
        /// A package configured with the predefined six month identifier.
         sixMonth,
        /// A package configured with the predefined three month identifier.
         threeMonth,
        /// A package configured with the predefined two month identifier.
         twoMonth,
        /// A package configured with the predefined monthly identifier.
         monthly,
        /// A package configured with the predefined weekly identifier.
         weekly
}

private extension PackageType {
    var description: String? {
        switch self {
        case .unknown: return nil
        case .custom: return nil
        case .lifetime: return "$rc_lifetime"
        case .annual: return "$rc_annual"
        case .sixMonth: return "$rc_six_month"
        case .threeMonth: return "$rc_three_month"
        case .twoMonth: return "$rc_two_month"
        case .monthly: return "$rc_monthly"
        case .weekly: return "$rc_weekly"
        }
    }

    static var typesByDescription: [String: PackageType] {
        [
            "$rc_lifetime": .lifetime,
            "$rc_annual": .annual,
            "$rc_six_month": .sixMonth,
            "$rc_three_month": .threeMonth,
            "$rc_two_month": .twoMonth,
            "$rc_monthly": .monthly,
            "$rc_weekly": .weekly,
        ]
    }
}

@objc(RCPackage) public class Package: NSObject {

    private let identifier: String
    private let packageType: PackageType
    private let product: SKProduct
    internal let offeringIdentifier: String

    init(identifier: String, packageType: PackageType, product: SKProduct, offeringIdentifier: String) {
        self.identifier = identifier
        self.packageType = packageType
        self.product = product
        self.offeringIdentifier = offeringIdentifier
    }

    public var localizedPriceString: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale

        return formatter.string(from: product.price) ?? ""
    }

    public var localizedIntroductoryPriceString: String {
        if #available(iOS 11.2, macOS 10.13.2, tvOS 11.2, *) {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = product.priceLocale

            if let price = product.introductoryPrice?.price {
                return formatter.string(from: price) ?? ""
            }
            return ""
        } else {
            return ""
        }
    }
}

extension Package {
    static func string(from packageType: PackageType) -> String? {
        return packageType.description
    }

    class func packageType(from string: String) -> PackageType {
        if let packageType = PackageType.typesByDescription[string] {
            return packageType
        }

        return string.hasPrefix("$rc_") ? .unknown : .custom
    }
}
