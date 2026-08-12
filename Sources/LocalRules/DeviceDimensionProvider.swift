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
    private let platformVersion: OperatingSystemVersion
    private let sdkVersion: String

    init(
        appVersion: String = SystemInfo.appVersion,
        localeProvider: @escaping @Sendable () -> String? = { Locale.preferredLanguages.first },
        platform: String = SystemInfo.platformHeaderConstant,
        platformVersion: OperatingSystemVersion = ProcessInfo.processInfo.operatingSystemVersion,
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
            variables["locale"] = .string(locale.lowercased().replacingOccurrences(of: "-", with: "_"))
        }

        if !self.platform.isEmpty {
            variables["platform"] = .string(self.platform.lowercased())
        }

        variables["platform_version"] = .string(Self.semanticVersion(self.platformVersion))

        if let sdkVersion = Self.semanticVersion(self.sdkVersion) {
            variables["sdk_version"] = .string(sdkVersion)
        }

        return variables
    }

    private static func semanticVersion(_ version: OperatingSystemVersion) -> String {
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    private static func semanticVersion(_ version: String) -> String? {
        let numericComponents = version
            .split(separator: ".", omittingEmptySubsequences: false)
            .prefix(3)
            .map { $0.prefix(while: { $0.isNumber }) }

        guard !numericComponents.isEmpty,
              numericComponents.allSatisfy({ !$0.isEmpty }) else {
            return nil
        }

        return (numericComponents.map(String.init) + Array(repeating: "0", count: 3 - numericComponents.count))
            .joined(separator: ".")
    }

}
