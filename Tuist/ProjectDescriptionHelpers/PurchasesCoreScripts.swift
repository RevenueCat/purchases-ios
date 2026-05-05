import Foundation
import ProjectDescription

extension TargetScript {
    /// A pre-build script phase that rebuilds a local `purchases-core`
    /// checkout when any Rust source changes. Only returns a non-empty array
    /// when `Environment.purchasesCoreLocalPath` is set; otherwise callers
    /// get `[]` and the generated target has no extra phases.
    ///
    /// The absolute path is resolved at `tuist generate` time (relative
    /// values are resolved against the repo root). Re-run `tuist generate`
    /// after changing the Local.xcconfig value.
    public static var purchasesCoreBuildScripts: [TargetScript] {
        guard let path = Environment.purchasesCoreLocalPath else { return [] }
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent() // ProjectDescriptionHelpers
            .deletingLastPathComponent() // Tuist
            .deletingLastPathComponent() // repo root
        let resolved = URL(fileURLWithPath: path, relativeTo: repoRoot).standardizedFileURL.path

        let script = """
        set -euo pipefail
        cd "\(resolved)"
        ./scripts/build-ios.sh
        """

        // Xcode's Run Script "input paths" hash each entry as a file — directory
        // entries only hash the directory's own metadata, not recursive contents.
        // So `src` as a directory input does NOT detect edits to files inside it.
        // Walk the tree at generate time and enumerate every `.rs` explicitly.
        // Add a new `.rs` file? Re-run `tuist generate` to pick it up.
        let manifests = ["Cargo.toml", "Cargo.lock", "uniffi.toml"]
            .map { "\(resolved)/\($0)" }
        let rustSources = enumerateRustSources(under: "\(resolved)/src")

        return [
            .pre(
                script: script,
                name: "Build local purchases-core",
                inputPaths: (manifests + rustSources).map { FileListGlob(stringLiteral: $0) },
                outputPaths: [
                    "\(resolved)/out/ios/PurchasesCore.xcframework/Info.plist"
                ],
                basedOnDependencyAnalysis: true
            )
        ]
    }

    private static func enumerateRustSources(under directory: String) -> [String] {
        let url = URL(fileURLWithPath: directory)
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }
        var results: [String] = []
        for case let fileURL as URL in enumerator where fileURL.pathExtension == "rs" {
            results.append(fileURL.standardizedFileURL.path)
        }
        return results.sorted()
    }
}
