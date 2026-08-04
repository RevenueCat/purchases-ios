//
//  Copyright RevenueCat Inc. All Rights Reserved.
//
//  Licensed under the MIT License (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      https://opensource.org/licenses/MIT
//
//  DemoCheckpointWorkflowPresentation.swift
//
//  Created by Rick van der Linden.
//

import Foundation

/// Demo-only presentation containing a bundled JSON workflow document.
@_spi(Internal) public final class DemoCheckpointWorkflowPresentation: CheckpointEnginePresentation {

    /// JSON data consumed by the PoC renderer in RevenueCatUI.
    public let workflowData: Data

    init(checkpoint: CheckpointEngineInfo, workflowData: Data) {
        self.workflowData = workflowData
        super.init(checkpoint: checkpoint)
    }

}
