//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  CheckpointPresenterFactory.swift
//
//  Created by Rick van der Linden.
//

@_spi(Internal) import RevenueCat

@MainActor
enum CheckpointPresenterFactory {

    static func makePresenter() -> CheckpointEnginePresenter? {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            // PoC-only: render the bundled JSON registered by CheckpointTester.
            return DemoCheckpointWorkflowPresenter()
        } else {
            return nil
        }
    }

}
