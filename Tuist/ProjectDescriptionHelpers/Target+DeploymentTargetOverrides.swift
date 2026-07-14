//
//  Target+DeploymentTargetOverrides.swift
//
//  Created by Antonio Pallares.
//

import ProjectDescription

extension Target {

    /// Returns a copy of the target with SDK-conditional deployment-target overrides, mirroring the
    /// conditional overrides committed to `RevenueCat.xcodeproj`.
    ///
    /// Newer Xcode SDKs raise the minimum deployment target they'll build (e.g. Xcode 27 enforces
    /// iOS 15 / tvOS 15 / watchOS 9 / macOS 12). Instead of raising the SDK's true minimums everywhere
    /// (which would drop support for older OSes on every Xcode), this adds `[sdk=*]`-conditional
    /// overrides that only take effect when building against those newer SDKs. The base deployment
    /// target — and every other SDK — is left untouched, so a single generated workspace keeps
    /// building across Xcode versions with no environment flag. Add future SDK floors here.
    ///
    /// It is safe to apply to every target: only platforms whose deployment target is *below* a floor
    /// are raised, so targets already at or above the floor are returned unchanged and no platform is
    /// ever lowered.
    public func addingXcodeDeploymentTargetOverrides() -> Target {
        guard let deploymentTargets else { return self }

        var overrides: SettingsDictionary = [:]

        func raiseToFloor(_ current: String?, floor: String, deviceSDK: String, simulatorSDK: String, buildSetting: String) {
            guard let current, current.rc_isVersionBelow(floor) else { return }
            overrides["\(buildSetting)[sdk=\(deviceSDK)27*]"] = .string(floor)
            overrides["\(buildSetting)[sdk=\(simulatorSDK)27*]"] = .string(floor)
        }

        // Xcode 27 floors.
        raiseToFloor(deploymentTargets.iOS, floor: "15.0",
                     deviceSDK: "iphoneos", simulatorSDK: "iphonesimulator",
                     buildSetting: "IPHONEOS_DEPLOYMENT_TARGET")
        raiseToFloor(deploymentTargets.tvOS, floor: "15.0",
                     deviceSDK: "appletvos", simulatorSDK: "appletvsimulator",
                     buildSetting: "TVOS_DEPLOYMENT_TARGET")
        raiseToFloor(deploymentTargets.watchOS, floor: "9.0",
                     deviceSDK: "watchos", simulatorSDK: "watchsimulator",
                     buildSetting: "WATCHOS_DEPLOYMENT_TARGET")

        // macOS exposes a single SDK name (no separate simulator), matching the committed .xcodeproj.
        if let macOS = deploymentTargets.macOS, macOS.rc_isVersionBelow("12.0") {
            overrides["MACOSX_DEPLOYMENT_TARGET[sdk=macosx27*]"] = "12.0"
        }

        guard !overrides.isEmpty else { return self }

        var target = self
        var settings = target.settings ?? .settings()
        settings.base = settings.base.merging(overrides)
        target.settings = settings
        return target
    }
}

extension [Target] {

    /// Applies ``Target/addingXcodeDeploymentTargetOverrides()`` to every target in the array.
    public func addingXcodeDeploymentTargetOverrides() -> [Target] {
        map { $0.addingXcodeDeploymentTargetOverrides() }
    }
}

private extension String {

    /// Compares dotted version strings (e.g. "13.0" < "15.0") numerically, component by component.
    func rc_isVersionBelow(_ other: String) -> Bool {
        let lhs = split(separator: ".").map { Int($0) ?? 0 }
        let rhs = other.split(separator: ".").map { Int($0) ?? 0 }
        for index in 0..<Swift.max(lhs.count, rhs.count) {
            let left = index < lhs.count ? lhs[index] : 0
            let right = index < rhs.count ? rhs[index] : 0
            if left != right { return left < right }
        }
        return false
    }
}
