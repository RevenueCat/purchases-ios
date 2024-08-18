//
//  PaywallLayoutComponent.swift
//
//
//  Created by James Borthwick on 2024-08-17.
//

import SwiftUI

public struct VStackComponent: Decodable, Sendable, Hashable {
    let components: [PaywallComponent]
    let alignment: HorizontalAlignment?
    let spacing: CGFloat?
    let backgroundColor: String?

    enum CodingKeys: String, CodingKey {
        case components
        case alignment
        case spacing
        case backgroundColor
    }
}

public struct HStackComponent: Decodable, Sendable, Hashable {
    let components: [PaywallComponent]
    let alignment: VerticalAlignment?
    let spacing: CGFloat?
    let backgroundColor: String?

    enum CodingKeys: String, CodingKey {
        case components
        case alignment
        case spacing
        case backgroundColor
    }
}

public struct ZStackComponent: Decodable, Sendable, Hashable {
    let components: [PaywallComponent]
    let alignment: Alignment?
    let backgroundColor: String?

    enum CodingKeys: String, CodingKey {
        case components
        case alignment
        case backgroundColor
    }
}


enum HorizontalAlignment: String, Decodable, Sendable, Hashable, Equatable {
    case leading
    case center
    case trailing

    public var alignment: SwiftUI.HorizontalAlignment {
        switch self {
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        }
    }
}

enum VerticalAlignment: String, Decodable, Sendable, Hashable, Equatable {
    case top
    case center
    case bottom

    public var alignment: SwiftUI.VerticalAlignment {
        switch self {
        case .top:
            return .top
        case .center:
            return .center
        case .bottom:
            return .bottom
        }
    }
}

enum Alignment: String, Decodable, Sendable, Hashable, Equatable {
    case topLeading
    case top
    case topTrailing
    case leading
    case center
    case trailing
    case bottomLeading
    case bottom
    case bottomTrailing

    public var alignment: SwiftUI.Alignment {
        switch self {
        case .topLeading:
            return .topLeading
        case .top:
            return .top
        case .topTrailing:
            return .topTrailing
        case .leading:
            return .leading
        case .center:
            return .center
        case .trailing:
            return .trailing
        case .bottomLeading:
            return .bottomLeading
        case .bottom:
            return .bottom
        case .bottomTrailing:
            return .bottomTrailing
        }
    }
}
