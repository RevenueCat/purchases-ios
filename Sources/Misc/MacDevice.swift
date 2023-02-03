//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  MacDevice.swift
//
//  Created by Juanpe Catalán on 30/11/21.

#if os(macOS) || targetEnvironment(macCatalyst)
import Foundation

#if canImport(IOKit)
import IOKit
#endif

enum MacDevice {

    // Based on Apple's documentation, the mac address must
    // be used to validate receipts.
    // https://developer.apple.com/documentation/appstorereceipts/validating_receipts_on_the_device
    static var identifierForVendor: UUID? {
        networkInterfaceMacAddressData?.uuid
    }

    static var networkInterfaceMacAddressData: Data? {
        #if canImport(IOKit)
        guard let service = getIOService(named: "en0", wantBuiltIn: true)
                ?? getIOService(named: "en1", wantBuiltIn: true)
                ?? getIOService(named: "en0", wantBuiltIn: false)
            else { return nil }

        defer { IOObjectRelease(service) }

        return IORegistryEntrySearchCFProperty(
            service,
            kIOServicePlane,
            "IOMACAddress" as CFString,
            kCFAllocatorDefault,
            IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents)
        ) as? Data
        #else
        return nil
        #endif
    }

    #if canImport(IOKit)
    static private func getIOService(named name: String, wantBuiltIn: Bool) -> io_service_t? {
        // 0 is `kIOMasterPortDefault` / `kIOMainPortDefault`, but the first is deprecated
        // And the second isn't available in Catalyst on Xcode 14.
        let defaultPort: mach_port_t = 0
        var iterator = io_iterator_t()
        defer {
            if iterator != IO_OBJECT_NULL {
                IOObjectRelease(iterator)
            }
        }

        guard let matchingDict = IOBSDNameMatching(defaultPort, 0, name),
              IOServiceGetMatchingServices(defaultPort,
                                           matchingDict as CFDictionary,
                                           &iterator) == KERN_SUCCESS,
              iterator != IO_OBJECT_NULL
        else {
            return nil
        }

        var candidate = IOIteratorNext(iterator)
        while candidate != IO_OBJECT_NULL {
            if let cftype = IORegistryEntryCreateCFProperty(candidate,
                                                            "IOBuiltin" as CFString,
                                                            kCFAllocatorDefault,
                                                            0) {
                // swiftlint:disable:next force_cast
                let isBuiltIn = cftype.takeRetainedValue() as! CFBoolean
                if wantBuiltIn == CFBooleanGetValue(isBuiltIn) {
                    return candidate
                }
            }

            IOObjectRelease(candidate)
            candidate = IOIteratorNext(iterator)
        }

        return nil
    }
    #endif

}

#endif
