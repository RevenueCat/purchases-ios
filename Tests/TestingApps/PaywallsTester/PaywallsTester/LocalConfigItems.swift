//
//  LocalConfigItems.swift
//  PaywallsTester
//
//  Created by James Borthwick on 2024-05-13.
//

import Foundation

// This file is used to store keys for local development
//
// DO NOT CHECK IN CHANGES TO THIS FILE
//
// To help prevent mistakes, mark this file inn your working directory sith --skip-worktree:
// git update-index --skip-worktree LocalKeys.swift
// OR assume unchanged:
// git update-index --assume-unchanged LocalKeys.swift
//
// You will need to unset these when switching branches
// git update-index --no-skip-worktree LocalKeys.swift
// git update-index --no-assume-unchanged LocalKeys.swift
//
// Then add local keys:
// extension ConfigItem {
//     static var apiKey: String {
//         "appl_FOObar"
//     }
// }
 extension ConfigItem {
    #warning("Configure API key if you want to test paywalls from your dashboard")
 }
