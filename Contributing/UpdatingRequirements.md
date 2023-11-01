### Build Requirements

The current list of build requirements is listed in `README.md`:
- Xcode version
- Deployment targets

https://xcodereleases.com can be used as a reference.

### Places to Update

If these requirements change, there are several places that need to be updated:
- `README.md`
- https://www.revenuecat.com/docs/getting-started
- Xcode `Project` build settings (at the project level; targets inherit these settings)
- `RevenueCat.podspec`
- `RevenueCatUI.podspec`
- `Package.swift`
- `SwiftVersionCheck.swift`

### Last

Once those are updated, it's possible that a lot of `@available` checks aren't required anymore, which would help clean up the codebase.
