//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  InstallmentsInfoFactory.swift
//
//  Created by Will Taylor on 5/11/26.

import Foundation
import StoreKit

protocol InstallmentsInfoFactoryType: Sendable {

#if compiler(>=6.3.2)
    @available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *)
    func buildInstallmentsInfo(
        from product: SK2Product,
        billingPlanType: StoreKit.Product.SubscriptionInfo.BillingPlanType,
        pricingTerms: StoreKit.Product.SubscriptionInfo.PricingTerms
    ) -> InstallmentsInfo?
#endif

}

final class InstallmentsInfoFactory: InstallmentsInfoFactoryType {

#if compiler(>=6.3.2)
    @available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *)
    func buildInstallmentsInfo(
        from product: SK2Product,
        billingPlanType: StoreKit.Product.SubscriptionInfo.BillingPlanType,
        pricingTerms: StoreKit.Product.SubscriptionInfo.PricingTerms
    ) -> InstallmentsInfo? {
        guard let installmentsCount = calculateInstallmentsCount(
            billingPlanType: billingPlanType,
            commitmentPeriod: pricingTerms.commitmentInfo.period
        ) else { return nil }

        guard let commitmentTotalPeriod = calculateCommitmentTotalPeriod(
            billingPlanType: billingPlanType,
            commitmentPeriod: pricingTerms.commitmentInfo.period
        ) else { return nil }

        let commitmentTotalPrice = pricingTerms.billingPrice * Decimal(installmentsCount)
        let commitmentTotalDisplayPrice: String = commitmentTotalPrice.formatted(product.priceFormatStyle)

        return self.buildInstallmentsInfo(
            billingPlanType: billingPlanType,
            commitmentPeriod: pricingTerms.commitmentInfo.period,
            billingPrice: pricingTerms.billingPrice,
            billingDisplayPrice: pricingTerms.billingDisplayPrice,
            installmentsCount: installmentsCount,
            commitmentTotalPeriod: commitmentTotalPeriod,
            commitmentTotalDisplayPrice: commitmentTotalDisplayPrice
        )
    }

    @available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *)
    func buildInstallmentsInfo(
        billingPlanType: StoreKit.Product.SubscriptionInfo.BillingPlanType,
        commitmentPeriod: StoreKit.Product.SubscriptionPeriod,
        billingPrice: Decimal,
        billingDisplayPrice: String,
        installmentsCount: Int? = nil,
        installmentPeriod: SubscriptionPeriod? = nil,
        commitmentTotalPeriod: SubscriptionPeriod? = nil,
        commitmentTotalDisplayPrice: String
    ) -> InstallmentsInfo? {
        guard let installmentsCount = installmentsCount ?? calculateInstallmentsCount(
            billingPlanType: billingPlanType,
            commitmentPeriod: commitmentPeriod
        ) else { return nil }

        guard let installmentPeriod = installmentPeriod ?? calculateInstallmentPeriod(
            billingPlanType: billingPlanType
        ) else { return nil }

        guard let commitmentTotalPeriod = commitmentTotalPeriod ?? calculateCommitmentTotalPeriod(
            billingPlanType: billingPlanType,
            commitmentPeriod: commitmentPeriod
        ) else { return nil }

        guard let rcBillingPlanType = BillingPlanType.from(storeKitBillingPlanType: billingPlanType) else {
            return nil
        }

        let commitmentTotalPrice = billingPrice * Decimal(installmentsCount)
        let installmentBillingPrice = billingPrice
        let installmentBillingDisplayPrice = billingDisplayPrice
        return InstallmentsInfo(
            installmentsCount: installmentsCount,
            installmentPeriod: installmentPeriod,
            installmentBillingPrice: installmentBillingPrice,
            installmentBillingDisplayPrice: installmentBillingDisplayPrice,
            commitmentTotalPeriod: commitmentTotalPeriod,
            commitmentTotalPrice: commitmentTotalPrice,
            commitmentTotalDisplayPrice: commitmentTotalDisplayPrice,
            billingPlanType: rcBillingPlanType
        )
    }
#endif

}

#if compiler(>=6.3.2)
extension InstallmentsInfoFactory {

    @available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *)
    func calculateInstallmentsCount(
        billingPlanType: StoreKit.Product.SubscriptionInfo.BillingPlanType,
        commitmentPeriod: StoreKit.Product.SubscriptionPeriod
    ) -> Int? {
        switch billingPlanType {
        case .monthly:
            switch commitmentPeriod {
            case .monthly: return 1
            case .everyTwoMonths: return 2
            case .everyThreeMonths: return 3
            case .everySixMonths: return 6
            case .yearly: return 12
            default:
                return nil
            }
        case .upFront:
            return nil
        default:
            return nil
        }
    }

    @available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *)
    func calculateInstallmentPeriod(
        billingPlanType: StoreKit.Product.SubscriptionInfo.BillingPlanType
    ) -> SubscriptionPeriod? {
        switch billingPlanType {
        case .monthly:
            return SubscriptionPeriod(value: 1, unit: .month)
        case .upFront:
            return nil
        default:
            return nil
        }
    }

    @available(iOS 26.4, tvOS 26.4, watchOS 26.4, macOS 26.4, visionOS 26.4, *)
    func calculateCommitmentTotalPeriod(
        billingPlanType: StoreKit.Product.SubscriptionInfo.BillingPlanType,
        commitmentPeriod: StoreKit.Product.SubscriptionPeriod
    ) -> SubscriptionPeriod? {
        switch billingPlanType {
        case .monthly:
            switch commitmentPeriod {
            case .monthly: return SubscriptionPeriod(value: 1, unit: .month)
            case .everyTwoMonths: return SubscriptionPeriod(value: 2, unit: .month)
            case .everyThreeMonths: return SubscriptionPeriod(value: 3, unit: .month)
            case .everySixMonths: return SubscriptionPeriod(value: 6, unit: .month)
            case .yearly: return SubscriptionPeriod(value: 1, unit: .year)
            default: return nil
            }
        case .upFront:
            return nil
        default:
            return nil
        }
    }

}
#endif
