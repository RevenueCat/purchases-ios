//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DangerousSettingsAPI.swift
//
//  Created by Antonio Pallares on 28/1/25.

@_spi(Internal) import RevenueCat

func checkDangerousSettingsAPI() {
    let _: DangerousSettings = DangerousSettings(uiPreviewMode: true)
}
