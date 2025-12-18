//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  RuntimeUtils.swift
//
//  Created by Facundo Menzella on 3/4/25.

enum RuntimeUtils {
     static var isSimulator: Bool {
 #if targetEnvironment(simulator)
         true
 #else
         false
 #endif
     }
 }
