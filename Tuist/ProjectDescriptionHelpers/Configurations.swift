import ProjectDescription

extension Array<Configuration> {

    /// Debug and Release configurations that use the Global.xcconfig file
    public static var xcconfigFileConfigurations: [Configuration] {
        [
            .debug(
                name: "Debug",
                settings: [
                    "SWIFT_COMPILATION_MODE": "incremental"
                ],
                xcconfig: .relativeToRoot("Global.xcconfig")
            ),
            .release(
                name: "Release",
                settings: [
                    "SWIFT_COMPILATION_MODE": "wholemodule"
                ],
                xcconfig: .relativeToRoot("Global.xcconfig")
            ),
        ]
    }
}
