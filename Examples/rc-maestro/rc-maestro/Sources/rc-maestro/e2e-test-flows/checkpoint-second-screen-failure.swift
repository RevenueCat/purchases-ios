//
//  checkpoint-second-screen-failure.swift
//  Maestro
//
//  Created by Rick van der Linden on 15/10/2026.
//  Copyright © 2026 RevenueCat, Inc. All rights reserved.
//

import SwiftUI

extension E2ETestFlowView {

    struct CheckpointInvalidIdentifier: View {
        var body: some View {
            CheckpointE2ETestView(testCase: .invalidIdentifier)
        }
    }

    struct CheckpointInvalidIdentifierCustomErrorPresenter: View {
        var body: some View {
            CheckpointE2ETestView(testCase: .invalidIdentifier, usesCustomErrorPresenter: true)
        }
    }

    struct CheckpointResolutionFailure: View {
        var body: some View {
            CheckpointE2ETestView(testCase: .resolutionFailure)
        }
    }

    struct CheckpointResolutionFailureCustomErrorPresenter: View {
        var body: some View {
            CheckpointE2ETestView(testCase: .resolutionFailure, usesCustomErrorPresenter: true)
        }
    }

    struct CheckpointConfigurationUnavailable: View {
        var body: some View {
            CheckpointE2ETestView(testCase: .configurationUnavailable)
        }
    }

    struct CheckpointConfigurationUnavailableCustomErrorPresenter: View {
        var body: some View {
            CheckpointE2ETestView(testCase: .configurationUnavailable, usesCustomErrorPresenter: true)
        }
    }

    struct CheckpointInitialScreenFailure: View {
        var body: some View {
            CheckpointE2ETestView(testCase: .initialScreenFailure)
        }
    }

    struct CheckpointInitialScreenFailureCustomErrorPresenter: View {
        var body: some View {
            CheckpointE2ETestView(testCase: .initialScreenFailure, usesCustomErrorPresenter: true)
        }
    }

    struct CheckpointSecondScreenFailure: View {

        var body: some View {
            CheckpointE2ETestView(testCase: .secondScreenFailure)
        }

    }

    struct CheckpointSecondScreenFailureCustomErrorPresenter: View {

        var body: some View {
            CheckpointE2ETestView(testCase: .secondScreenFailure, usesCustomErrorPresenter: true)
        }

    }

    struct CheckpointPurchaseFailure: View {
        var body: some View {
            CheckpointE2ETestView(testCase: .purchaseFailure)
        }
    }

    struct CheckpointPurchaseFailureCustomErrorPresenter: View {
        var body: some View {
            CheckpointE2ETestView(testCase: .purchaseFailure, usesCustomErrorPresenter: true)
        }
    }

    struct CheckpointResultSyncFailure: View {
        var body: some View {
            CheckpointE2ETestView(testCase: .resultSyncFailure)
        }
    }

    struct CheckpointResultSyncFailureCustomErrorPresenter: View {
        var body: some View {
            CheckpointE2ETestView(testCase: .resultSyncFailure, usesCustomErrorPresenter: true)
        }
    }

    struct CheckpointSuccessfulWorkflow: View {
        var body: some View {
            CheckpointE2ETestView(testCase: .successfulWorkflow)
        }
    }

    struct CheckpointNoMatch: View {
        var body: some View {
            CheckpointE2ETestView(testCase: .noMatch)
        }
    }

    struct CheckpointInitialScreenFailureJapanese: View {
        var body: some View {
            CheckpointE2ETestView(testCase: .initialScreenFailure, preferredUILocale: "ja")
        }
    }

    struct CheckpointSecondScreenFailureSpanish: View {
        var body: some View {
            CheckpointE2ETestView(testCase: .secondScreenFailure, preferredUILocale: "es_ES")
        }
    }

    struct CheckpointPublished: View {
        var body: some View {
            CheckpointBackendE2ETestView(
                checkpointIdentifier: UserDefaults.standard.string(forKey: "checkpoint_identifier") ??
                    "donottouch_sdk_everyone"
            )
        }
    }

    struct CheckpointPublishedCustomErrorPresenter: View {
        var body: some View {
            CheckpointBackendE2ETestView(
                checkpointIdentifier: UserDefaults.standard.string(forKey: "checkpoint_identifier") ??
                    "donottouch_sdk_everyone",
                usesCustomErrorPresenter: true
            )
        }
    }

}
