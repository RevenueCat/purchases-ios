//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MapAppStoreDetector.swift
//
//  Created by Nacho Soto on 1/10/24.

import Foundation

/// A type that can determine whether the application is running on the MAS.
protocol MacAppStoreDetector: Sendable {

    var isMacAppStore: Bool { get }

}

#if os(macOS) || targetEnvironment(macCatalyst)

final class DefaultMacAppStoreDetector: MacAppStoreDetector {

    /// Returns whether the bundle was signed for Mac App Store distribution by checking
    /// the existence of a specific extension (marker OID) on the code signing certificate.
    ///
    /// This routine is inspired by the source code from ProcInfo, the underlying library
    /// of the WhatsYourSign code signature checking tool developed by Objective-See. Initially,
    /// it checked the common name but was changed to an extension check to make it more
    /// future-proof.
    ///
    /// For more information, see the following references:
    /// - https://github.com/objective-see/ProcInfo/blob/master/procInfo/Signing.m#L184-L247
    /// - https://gist.github.com/lukaskubanek/cbfcab29c0c93e0e9e0a16ab09586996#gistcomment-3993808
    var isMacAppStore: Bool {
        var status = noErr

        var code: SecStaticCode?
        status = SecStaticCodeCreateWithPath(Bundle.main.bundleURL as CFURL, [], &code)

        guard status == noErr, let code = code else {
            Logger.error(Strings.receipt.error_validating_bundle_signature)
            return false
        }

        var requirement: SecRequirement?
        status = SecRequirementCreateWithString(
            "anchor apple generic and certificate leaf[field.1.2.840.113635.100.6.1.9]" as CFString,
            [], // default
            &requirement
        )

        guard status == noErr, let requirement = requirement else {
            Logger.error(Strings.receipt.error_validating_bundle_signature)
            return false
        }

        status = SecStaticCodeCheckValidity(
            code,
            [], // default
            requirement
        )

        return status == errSecSuccess
    }

}

#endif
