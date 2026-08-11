//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DeviceDimensionProvider.swift
//
//  Created by Rick van der Linden on 8/11/26.
//

import Foundation

/// Supplies app and device information to the local rules engine.
struct DeviceDimensionProvider: DimensionProvider {

    let identifier = "device"
    let namespace = DimensionNamespace.device

    private let appVersion: String
    private let localeProvider: @Sendable () -> String?
    private let platform: String
    private let platformVersion: String
    private let sdkVersion: String

    init(
        appVersion: String = SystemInfo.appVersion,
        localeProvider: @escaping @Sendable () -> String? = { Locale.preferredLanguages.first },
        platform: String = SystemInfo.platformHeader,
        platformVersion: String = SystemInfo.systemVersion,
        sdkVersion: String = SystemInfo.frameworkVersion
    ) {
        self.appVersion = appVersion
        self.localeProvider = localeProvider
        self.platform = platform
        self.platformVersion = platformVersion
        self.sdkVersion = sdkVersion
    }

    func dimensions(at _: Date) async throws -> [String: DimensionValue] {
        var variables: [String: DimensionValue] = [:]

        if !self.appVersion.isEmpty {
            variables["app_version"] = .string(self.appVersion)
        }

        if let locale = self.localeProvider(), !locale.isEmpty {
            variables["locale"] = .string(locale)
        }

        if !self.platform.isEmpty {
            variables["platform"] = .string(self.platform)
        }

        if !self.platformVersion.isEmpty {
            variables["platform_version"] = .string(self.platformVersion)
        }

        if !self.sdkVersion.isEmpty {
            variables["sdk_version"] = .string(self.sdkVersion)
        }

        return variables
    }

}
