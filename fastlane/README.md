fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios setup_dev

```sh
[bundle exec] fastlane ios setup_dev
```

Setup development environment

### ios test

```sh
[bundle exec] fastlane ios test
```

Runs all the tests

### ios replace_version_number

```sh
[bundle exec] fastlane ios replace_version_number
```

Replace version number in project and supporting files

### ios bump_and_update_changelog

```sh
[bundle exec] fastlane ios bump_and_update_changelog
```

Increment build number and update changelog

### ios github_release

```sh
[bundle exec] fastlane ios github_release
```

Make github release

### ios create_sandbox_account

```sh
[bundle exec] fastlane ios create_sandbox_account
```

Create sandbox account

### ios release_checks

```sh
[bundle exec] fastlane ios release_checks
```

Release checks

### ios build_tv_watch_mac

```sh
[bundle exec] fastlane ios build_tv_watch_mac
```

build tvOS, watchOS, macOS

### ios build_mac

```sh
[bundle exec] fastlane ios build_mac
```

macOS build

### ios carthage_archive

```sh
[bundle exec] fastlane ios carthage_archive
```

Run the carthage archive steps to prepare for carthage distribution

### ios archive

```sh
[bundle exec] fastlane ios archive
```

archive

### ios archive_all_platforms

```sh
[bundle exec] fastlane ios archive_all_platforms
```

archive all platforms

### ios build_swift_api_tester

```sh
[bundle exec] fastlane ios build_swift_api_tester
```

build Swift API tester

### ios build_objc_api_tester

```sh
[bundle exec] fastlane ios build_objc_api_tester
```

build ObjC API tester

### ios replace_api_key_integration_tests

```sh
[bundle exec] fastlane ios replace_api_key_integration_tests
```

replace API KEY for integration tests

### ios release

```sh
[bundle exec] fastlane ios release
```

Release to CocoaPods, create Carthage archive, export XCFramework, and create GitHub release

### ios bump

```sh
[bundle exec] fastlane ios bump
```

Bump version, edit changelog, and create pull request

### ios compile_docs

```sh
[bundle exec] fastlane ios compile_docs
```

Compiles Docc archive

### ios deploy_docs

```sh
[bundle exec] fastlane ios deploy_docs
```

Deploys Docc archive

### ios prepare_next_version

```sh
[bundle exec] fastlane ios prepare_next_version
```

Prepare next version

### ios export_xcframework

```sh
[bundle exec] fastlane ios export_xcframework
```

Export XCFramework

### ios backend_integration_tests

```sh
[bundle exec] fastlane ios backend_integration_tests
```

Run BackendIntegrationTests

### ios update_swift_package_commit

```sh
[bundle exec] fastlane ios update_swift_package_commit
```

Update swift package commit

### ios sandbox_testers

```sh
[bundle exec] fastlane ios sandbox_testers
```

Create or delete sandbox testers

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
