# CheckpointTester

`CheckpointTester` is a Tuist-generated example for the experimental checkpoint APIs.

It demonstrates the core checkpoint cases:

- a checkpoint that presents UI;
- a checkpoint with no matching experience;
- a simulated checkpoint error;
- purchased, restored, dismissed, and error UI outcomes.

It also includes soft paywall, hard paywall, and onboarding examples. Every presented
experience is defined by a JSON document in `CheckpointTester/Resources` and rendered by
the experimental server-driven workflow presenter in RevenueCatUI.

At launch, the app reads the JSON files into a `[workflowID: Data]` dictionary and supplies it
to the SDK using the temporary `setCheckpointWorkflowData` SPI. Each demo checkpoint identifier
selects the workflow with the same identifier. Calls include `name: "Rick"` as an example custom
property that could be used by targeting configuration from RevenueCat's backend. The core SDK
passes the JSON unchanged to RevenueCatUI, where it is decoded and rendered.

The deliberately small JSON schema supports:

- dismissible and non-dismissible presentation;
- multi-page workflows;
- image, title, body, and feature components;
- next, previous, purchase, restore, dismiss, complete, and error actions;
- primary, secondary, and destructive button styles.

Generate the project from the repository root:

```sh
TUIST_RC_API_KEY=appl_your_key tuist generate CheckpointTester --no-open
```

The app configures RevenueCat before showing its root screen, so generation requires a valid
public iOS API key.
