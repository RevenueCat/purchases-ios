import ProjectDescription

extension Target {

    /// Attaches Tuist target `tags` (cosmetic, used only for `tuist graph`/focus filtering).
    /// Gated on Swift 5.9+: the Xcode 14.3.1 lane pins Tuist 4.45.1, whose ProjectDescription
    /// predates the `metadata` API, so tags are simply dropped there. Does not affect generation or GUIDs.
    public func tagged(_ tags: [String]) -> Target {
        #if compiler(>=5.9)
        var copy = self
        copy.metadata = .metadata(tags: tags)
        return copy
        #else
        return self
        #endif
    }
}
