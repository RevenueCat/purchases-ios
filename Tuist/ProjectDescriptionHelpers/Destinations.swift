import ProjectDescription

extension Destinations {

    /// Destinations for all RevenueCat targets (RevenueCat, RevenueCatUI)
    public static var allRevenueCat: Destinations {
        [
            .iPhone,
            .iPad,
            .mac,
            .macWithiPadDesign,
            .macCatalyst,
            .appleWatch,
            .appleTv,
            .appleVision,
            .appleVisionWithiPadDesign
        ]
    }

    /// All Apple platform destinations, with optional macWithiPadDesign support.
    /// - Parameter macWithiPadDesign: Whether to include the `.macWithiPadDesign` destination.
    /// - Returns: A set of all relevant Apple destinations.
    public static func allPlatforms(macWithiPadDesign: Bool) -> Destinations {
        let destinations: [Destination?] = [
            .iPhone,
            .iPad,
            .mac,
            macWithiPadDesign ? .macWithiPadDesign : nil,
            .macCatalyst,
            .appleWatch,
            .appleTv,
            .appleVision,
            .appleVisionWithiPadDesign
        ]
        return Set(destinations.compactMap { $0 })
    }
}
