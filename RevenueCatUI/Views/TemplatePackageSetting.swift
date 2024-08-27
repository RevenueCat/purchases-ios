//
//  TemplatePackageSetting.swift
//
//
//  Created by Nacho Soto on 2/8/24.
//

import Foundation

/// Whether a template displays 1 or multiple packages.
enum TemplatePackageSetting: Equatable {

    case single
    case multiple
    case multiTier

}

/// Whether a template displays 1 or multiple tiers.
enum TemplateTierSetting: Equatable {

    /// Single-tier template.
    case single

    /// Multi-tier template.
    case multiple

}

@available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *)
extension PaywallTemplate {

    var packageSetting: TemplatePackageSetting {
        switch self {
        case .template1: return .single
        case .template2: return .multiple
        case .template3: return .single
        case .template4: return .multiple
        case .template5: return .multiple
        case .template7: return .multiTier
        }
    }

}

extension TemplatePackageSetting {

    var tierSetting: TemplateTierSetting {
        switch self {
        case .single, .multiple: return .single
        case .multiTier: return .multiple
        }
    }

}
