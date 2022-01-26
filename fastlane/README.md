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

### ios bump

```sh
[bundle exec] fastlane ios bump
```

Increment build number

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

### ios deployment_checks

```sh
[bundle exec] fastlane ios deployment_checks
```

Deployment checks

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

### ios replace_api_key_integration_tests

```sh
[bundle exec] fastlane ios replace_api_key_integration_tests
```

replace API KEY for integration tests

### ios deploy

```sh
[bundle exec] fastlane ios deploy
```

Deploy

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

### ios storekit_tests

```sh
[bundle exec] fastlane ios storekit_tests
```

Run StoreKitTests

### ios update_swift_package_commit

```sh
[bundle exec] fastlane ios update_swift_package_commit
```

Update swift package commit

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
