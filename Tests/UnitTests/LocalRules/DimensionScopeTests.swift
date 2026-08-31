//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DimensionScopeTests.swift
//
//  Created by Rick van der Linden on 8/31/26.
//

// Swift Testing is only available with the Xcode 16+ toolchain
#if compiler(>=5.9)
#if canImport(Testing)

import Foundation
import Testing

@testable import RevenueCat

@Suite("Dimension scope")
struct DimensionScopeTests {

    @Test
    func canonicalSnapshotCombinesEveryDimensionSource() async throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let attribute = SubscriberAttribute(
            withKey: "goal",
            value: "make_more_money",
            isSynced: true,
            setTime: Date(timeIntervalSince1970: 1_699_999_000)
        )
        let providers: [any DimensionProvider] = [
            DeviceDimensionProvider(
                appVersion: "1.2.3",
                localeProvider: { "en-GB" },
                platform: "iOS",
                platformVersion: OperatingSystemVersion(majorVersion: 18, minorVersion: 5, patchVersion: 0),
                sdkVersion: "10.1.1"
            ),
            StoreDimensionProvider(storefrontCountryCodeProvider: { "GBR" }),
            CustomerInfoDimensionProvider(
                currentAppUserIDProvider: { "current_user" },
                customerInfoProvider: { _ in try CustomerInfo(data: Self.customerInfoData) }
            ),
            SubscriberAttributesDimensionProvider(attributesProvider: { ["goal": attribute] }),
            SubscriberDimensionsProvider(cachedDimensionsProvider: {
                Data(#"{"acquisition_channel":"paid_search","predicted_ltv_band":3}"#.utf8)
            })
        ]

        let snapshot = try await DimensionResolver(
            dimensionProviders: providers,
            dateProvider: MockDateProvider(stubbedNow: date)
        ).snapshot(
            customVariables: ["attempt": .int(3)],
            backendValues: ["condition_hash": .bool(true)]
        )

        #expect(snapshot.values == Self.expectedValues)
    }
}

private extension DimensionScopeTests {

    static let expectedValues: [String: RulesEngine.Value] = [
        "evaluated_at": .int(1_700_000_000_000),
        "app_version": .string("1.2.3"),
        "platform": .string("ios"),
        "platform_version": .string("18.5.0"),
        "locale": .string("en_gb"),
        "sdk_version": .string("10.1.1"),
        "storefront": .string("GBR"),
        "acquisition_channel": .string("paid_search"),
        "predicted_ltv_band": .int(3),
        "app_user_id": .string("current_user"),
        "original_app_user_id": .string("original_user"),
        "first_seen_at": .int(1_672_531_200_000),
        "original_purchased_at": .int(1_675_209_600_000),
        "purchases": .array([
            .object([
                "kind": .string("subscription"),
                "product_identifier": .string("premium"),
                "purchased_product_identifier": .string("premium"),
                "store": .string("app_store"),
                "ownership_type": .string("PURCHASED"),
                "period_type": .string("normal"),
                "status": .string("active"),
                "purchased_at": .int(1_698_796_800_000),
                "original_purchased_at": .int(1_675_209_600_000),
                "expires_at": .int(4_102_444_800_000),
                "is_active": .bool(true),
                "is_sandbox": .bool(false),
                "will_renew": .bool(true),
                "is_in_grace_period": .bool(false),
                "is_refunded": .bool(false),
                "is_paused": .bool(false)
            ])
        ]),
        "entitlements": .array([
            .object([
                "identifier": .string("premium"),
                "product_identifier": .string("premium"),
                "purchased_product_identifier": .string("premium"),
                "store": .string("app_store"),
                "ownership_type": .string("PURCHASED"),
                "period_type": .string("normal"),
                "latest_purchased_at": .int(1_698_796_800_000),
                "original_purchased_at": .int(1_675_209_600_000),
                "expires_at": .int(4_102_444_800_000),
                "is_active": .bool(true),
                "is_sandbox": .bool(false),
                "will_renew": .bool(true)
            ])
        ]),
        "subscriber_attributes": .object([
            "goal": .object([
                "updated_at": .int(1_699_999_000_000),
                "value": .string("make_more_money")
            ])
        ]),
        "custom": .object(["attempt": .int(3)]),
        "backend": .object(["condition_hash": .bool(true)])
    ]

    static let customerInfoData: [String: Any] = [
        "request_date": "2023-11-14T22:13:20Z",
        "subscriber": [
            "first_seen": "2023-01-01T00:00:00Z",
            "original_app_user_id": "original_user",
            "original_application_version": "1.0",
            "original_purchase_date": "2023-02-01T00:00:00Z",
            "non_subscriptions": [String: Any](),
            "subscriptions": [
                "premium": [
                    "store": "app_store",
                    "purchase_date": "2023-11-01T00:00:00Z",
                    "original_purchase_date": "2023-02-01T00:00:00Z",
                    "expires_date": "2100-01-01T00:00:00Z",
                    "period_type": "normal",
                    "ownership_type": "PURCHASED",
                    "is_sandbox": false
                ]
            ],
            "entitlements": [
                "premium": [
                    "expires_date": "2100-01-01T00:00:00Z",
                    "product_identifier": "premium",
                    "purchase_date": "2023-11-01T00:00:00Z"
                ]
            ]
        ]
    ]
}

#endif
#endif
