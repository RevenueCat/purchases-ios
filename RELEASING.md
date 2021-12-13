#### Releasing:
1. Create a `fastlane/.env` file with GitHub API token (see `fastlane/.env.SAMPLE`)
2. Run `bundle exec fastlane bump`
    1. Input new version number
    2. Update changelog
    3. A new branch and PR will automatically be created
3. Merge PR when approved
4. Make a tag and push, the rest will be performed automatically by CircleCI. If the automation fails, you can revert to manually calling `bundle exec fastlane deploy`.
