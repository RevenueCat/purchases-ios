#### Releasing:
1. Create a `fastlane/.env` file with your GitHub API token (see `fastlane/.env.SAMPLE`). This will be used to create the PR, so you should use your own token so the PR gets assigned to you. 
2. Run `bundle exec fastlane ios bump_ios`
    1. Input new version number
    2. Update CHANGELOG.latest.md to include the latest changes. Call out API changes (if any). You can use the existing CHANGELOG.md as a base for formatting. To compile the changelog, you can compare the changes between the base branch for the release (usually main) against the latest release, by checking https://github.com/revenuecat/purchases-ios/compare/<latest_release>...<base_branch>. For example, https://github.com/revenuecat/purchases-ios/compare/4.1.0...main. 
    3. A new branch and PR will automatically be created
3. Merge PR when approved
4. Make a tag and push, the rest will be performed automatically by CircleCI. If the automation fails, you can revert to manually calling `bundle exec fastlane deploy`.
