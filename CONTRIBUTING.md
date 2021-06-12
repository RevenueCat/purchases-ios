## Contributing

#### 1. Create an issue to make sure its something that should be done.

Before submitting a Github issue, please make sure to

- Search for [existing Github issues](https://github.com/RevenueCat/purchases-ios/issues)
- Review our [Help Center](https://support.revenuecat.com/hc/en-us)
- Read our [docs.revenuecat.com](https://docs.revenuecat.com/)

## Common project specific issues.

There are certain project specific issues that are commonly misinterpreted as bugs.

- [Offerings, products, or available packages are empty](https://support.revenuecat.com/hc/en-us/articles/360041793174)
- [Invalid Play Store credentials errors](https://support.revenuecat.com/hc/en-us/articles/360046398913)
- [Unable to connect to the App Store (STORE_PROBLEM) errors](https://support.revenuecat.com/hc/en-us/articles/360046399333)

For support I'd recommend our [online community](https://spectrum.chat/revenuecat), [StackOverflow](https://stackoverflow.com/tags/revenuecat/) and/or [Help Center](https://support.revenuecat.com/hc/en-us) 👍

If you have a clearly defined bug (with a [Minimal, Complete, and Reproducible example](https://stackoverflow.com/help/minimal-reproducible-example)) that is not specific to your project, follow the steps in the GitHub Issue template to file it with RevenueCat without removing any of the steps. For SDK-related bugs, make sure they can be reproduced on a physical device, not a simulator (there are simulator-specific problems that prevent purchases from working).

#### 2. Create a fork/branch.

#### 3. Setup your development environment.

##### Install fastlane.

We use fastlane 🚀 for all our automation, including setting up out dev environment.

```bash
$brew install fastlane
```

##### Run the setup lane.

```bash
$fastlane setup_dev
```

This installs [Homebrew](https://brew.sh/), and then [SwiftLint](https://github.com/realm/SwiftLint). After, it links in our pre-commit hook to run swiftlint. That saves you time so you don't have to wait for our CI to do it ⏱.

#### 5. Build something!

We don't have a style guide, yet, but when coding please try to match the prevailing style of the project. This is pretty subjective, so don't get too stressed about it. If there's any issue, we'll suggest a change.

#### 6. Write tests for your fix/new functionality.

You can run the tests by selecting the All Tests Scheme in Xcode and hitting `Cmd+U`.
The tests are written in Swift, using XCTest and [Nimble](https://github.com/quick/nimble).

#### 7. Create a pull request to revenuecat/main and request review.

Explain in your pull request the work that was done and the reasoning.

#### 8. Make changes in response to review.

#### 9. Bask in the glory of community maintained software 😎
