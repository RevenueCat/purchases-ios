import ProjectDescription

extension Array<Configuration> {

    /// Debug and Release configurations that use the Global.xcconfig file
    public static var xcconfigFileConfigurations: [Configuration] {
        [
            .debug(name: "Debug", xcconfig: .relativeToRoot("Global.xcconfig")),
            .release(name: "Release", xcconfig: .relativeToRoot("Global.xcconfig")),
        ]
    }
}
