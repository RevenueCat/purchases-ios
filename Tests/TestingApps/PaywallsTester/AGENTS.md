# PaywallsTester

The SDK's testing app. Alongside the normal offering-driven screens it carries a
**live JSON harness**: a screen that renders a paywall from a file on disk and
re-renders whenever that file changes, so paywall JSON can be iterated on without
rebuilding.

## Live JSON harness

`PaywallsTester/UI/Views/LiveJSONPaywallView.swift`

Watches a directory, renders the selected `*.json` through the real SDK layout
engine, and reloads within ~300ms of a write. Useful for checking what the
shipped iOS renderer does with a paywall, as opposed to what the web renderer
draws in the dashboard preview.

Change detection is a modification-date/size poll, not a `DispatchSource` vnode
watch. Editors and agents write atomically, which replaces the inode and silently
detaches a vnode source; an in-place write does not fire the directory's vnode
event either. Polling catches both.

### Where it looks for JSON

In order:

1. `LIVE_PAYWALL_DIR`, if set.
2. `$SIMULATOR_HOST_HOME/rc/paywall-live`, which resolves on the simulator to the
   host Mac's home. This is why the default watch folder lives outside the repo.
3. A folder you pick, remembered as a security-scoped bookmark.

### Accepted JSON shapes

- a whole `PaywallComponentsData` document
- `{ "paywall": …, "ui_config": … }`
- a **split mafdet export**: drop both `<id>-components.json` and
  `<id>-localizations.json` in the folder and select the *components* half. The
  localizations sibling is paired by filename prefix and hidden from the picker.

`template_name`, `asset_base_url` and `revision` are filled in if missing. No
export path includes them, and without them `PaywallComponentsData` decoding
falls back to the default template rather than erroring, which looks like a
layout bug and is not one.

### Environment

| variable | effect |
|---|---|
| `LIVE_PAYWALL_DIR` | the folder to watch |
| `LIVE_PAYWALL_LABEL` | badge text in the popover, for telling two builds apart |

Pass these to a simulator with the `SIMCTL_CHILD_` prefix.

## Running it

### iOS simulator

```bash
export DEVELOPER_DIR=/Applications/Xcode-26.6.0.app/Contents/Developer
SIMCTL_CHILD_LIVE_PAYWALL_DIR=$HOME/rc/paywall-live \
SIMCTL_CHILD_LIVE_PAYWALL_LABEL="min/max" \
  xcrun simctl launch <device-udid> com.revenuecat.PaywallsTester
```

### Mac Catalyst

Prefer this for responsive work. `\.paywallWindowSize` is the paywall's rendered
container bounds, not the device screen (see `ScreenCondition.swift`), so a
freely resizable Catalyst window drives the window size conditions and min/max
rules directly. Xcode 26.6 has no Resizable simulator device types. A Catalyst
window will not go below ~500pt wide, so narrower cases need a simulator.

```bash
export DEVELOPER_DIR=/Applications/Xcode-26.6.0.app/Contents/Developer
xcodebuild -project Tests/TestingApps/PaywallsTester/PaywallsTester.xcodeproj \
  -scheme 'PaywallsTester - SK config' \
  -destination 'platform=macOS,variant=Mac Catalyst' \
  -derivedDataPath .build-catalyst \
  CODE_SIGN_IDENTITY="-" CODE_SIGN_ENTITLEMENTS="" DEVELOPMENT_TEAM="" \
  build

env LIVE_PAYWALL_DIR="$PWD/paywall-live" \
  .build-catalyst/Build/Products/Debug-maccatalyst/PaywallsTester.app/Contents/MacOS/PaywallsTester
```

Ad-hoc signing with the entitlements cleared also drops the app sandbox, so the
app reads host paths directly and no folder picker is needed. Launch the binary
rather than `open`ing the bundle: `open` goes through LaunchServices, so the app
inherits the launchd environment and never sees `LIVE_PAYWALL_DIR`.

The scheme names are `PaywallsTester - SK config`, `PaywallsTester - Live Config`
and `PaywallsTester - macOS Focus Regression`. There is no scheme called plain
`PaywallsTester`.

## Loading a real paywall

`loadpaywall` takes a dashboard builder URL, fetches it through the mafdet CLI,
reassembles the halves into the one document the SDK expects, and writes
`live.json` into the watch folder.

```bash
scripts/loadpaywall "https://app.revenuecat.com/projects/<id>/paywalls/<pw…|wf…>/builder"
```

Both URL shapes work. `paywalls/pw…` is a single paywall and comes from
`mafdet paywall components` plus `mafdet paywall localizations`; `paywalls/wf…`
is a workflow and comes from `mafdet workflow steps|screen`, with `--list` and
`--screen <id>` for choosing among its screens.

The dashboard stores structure and copy separately and every export path hands
them over separately, so neither half renders on its own. That reassembly is the
point of the script.

Gotchas:

- Route mafdet output through `-o <file>`, never stdout. The CLI corrupts
  multi-byte characters that straddle a 160 KiB stdout chunk boundary.
- mafdet auth expires roughly hourly. `mafdet auth login` to refresh.
- `zero_decimal_place_countries` arrives as a flat list and must be reshaped to
  `{"apple": [...]}` for iOS.

## Editing the loaded JSON

Anything that writes the file works, and the app reloads on its own. But once a
paywall is loaded, **a request to change it means running it through Astra**, not
hand-editing the document:

```bash
scripts/astraedit "<the user's request, verbatim>"
```

That is the point of the setup. Astra judges its own output against the bundled
**web** renderer, so it can be confidently wrong about what iOS ships, and this
harness exists to show that divergence. Hand-editing the JSON tests only your own
reading of the schema instead, which is not what the user is looking at. Pass the
request through as phrased rather than translating it into schema terms first,
since how Astra reads plain language is part of what is being tested.

`astraedit` needs `ASTRA_DIR` pointing at `packages/astra` in a checkout of
RevenueCat/agents, plus a small addition described in INSTALL.md. It runs through
the eval harness rather than Astra's editor API, because that endpoint wants a
dashboard cookie even against a local server, while eval cases carry their own
`feature_flags` and `paywall_size` inline. Each run is a fresh conversation:
turns chain by re-seeding from the current paywall, not by session id.

Editing `paywall-live/live.json` directly, with Claude Code or by hand, is the
fallback when Astra is not set up, when a specific JSON edit is asked for, or when
building a probe to test a layout rule rather than a design.

## Always report what changed in the JSON

Whenever you change the paywall JSON, whether by hand or through Astra, tell the
user **what changed in the document**, not just what you did. Name the path, the
before value and the after value:

```
  .base.stack.size.width
    before: {"type": "fill"}
    after : {"type": "fill", "max": 600}

1 node changed
```

The whole point of the harness is watching a specific JSON change produce a
specific layout change, and a rendered screenshot alone does not say which
property caused it. A restructure that touches thousands of nodes still has a
handful that matter, so summarise those and give the total rather than dumping
the diff.

`scripts/astraedit` prints this automatically. When editing the file directly,
produce the same thing.

## Reading a render correctly

- The harness draws exactly one thing on the paywall: the `…` button, bottom
  right. Everything else on screen belongs to the paywall, including any back
  chevron or close button.
- The paywall gets the whole window, so the container width equals the window
  width. There is no inset to subtract.
- `SizeConstraint.init(from:)` has a blanket catch that degrades a malformed size
  to `.fit`, so a typo in a size object shows up as a layout oddity rather than a
  decoding error.
- The harness deliberately renders full screen with no `TabView`. A tab bar takes
  a slice of the window, and since `paywallWindowSize` measures the container, the
  responsive rules would then evaluate against a size the real app never produces.
