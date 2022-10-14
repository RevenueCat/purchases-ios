//
//  SDKTesterAPI.swift
//  SwiftAPITester
//
//  Created by Nacho Soto on 10/10/22.
//

import Foundation
import RevenueCat

func checkSDKTester() {
    let _: SDKTester = .default
}

private func checkSDKTesterAsync(_ tester: SDKTester) async {
    _ = try? await tester.test()
}

func checkSDKTesterErrors(_ error: SDKTester.Error) {
    switch error {
    case let .failedConnectingToAPI(error):
        print(error)

    case .invalidAPIKey:
        break

    case let .failedFetchingOfferings(error):
        print(error)

    case let .unknown(error):
        print(error)

    @unknown default: break
    }
}
