# RC Container Fixtures

The `.bin` files in `Tests/UnitTests/Networking/Responses/Fixtures/RCContainer` are frozen RC Container v1 fixtures. They exist to catch accidental backwards-incompatible parser changes that in-memory builder tests could miss.

Regenerate them only after an intentional fixture or wire-compatibility change, or when introducing
a new major version of the RC Container format:

1. Run only `UnitTests/RCContainerBackwardsCompatibilityTests/testGenerateFixtures`.
2. Pass `GENERATE_RC_CONTAINER_FIXTURES=1` as a test runner environment value.

When running through `xcodebuildmcp`, use the same focused XCTest identifier and pass
`GENERATE_RC_CONTAINER_FIXTURES=1` in `testRunnerEnv`. The generator also accepts
`TEST_RUNNER_GENERATE_RC_CONTAINER_FIXTURES=1`, which matches the environment name exposed by
`xcodebuildmcp`.

After regenerating, run the focused RC Container tests and review the binary diffs before committing.
