import ProjectDescription

let tuist = Tuist(
    project: .tuist(
        swiftVersion: Version(5, 10, 0),
        generationOptions: .options(
        staticSideEffectsWarningTargets: .all,
        enforceExplicitDependencies: true
        )
    )
)


public enum ThisIsOneMoreTest {
    case test
}