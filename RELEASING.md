#### Releasing: 
1. Start a git-flow release/x.y.z
1. Create a CHANGELOG.latest.md with the changes for the current 
version (to be used by Fastlane for the github release notes)
1. Update the version number by running `bundle exec fastlane bump_and_update_changelog version:x.y.z`
1. Commit the changes `git commit -am "Version x.y.z"`
1. Make a PR, merge when approved
1. Make a tag and push, the rest will be performed automatically by CircleCI. If the automation fails, you can revert to manually calling `bundle exec fastlane deploy`.
