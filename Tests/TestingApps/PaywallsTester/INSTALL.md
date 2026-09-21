# Setting up the live paywall harness

Instructions for getting the live-JSON harness running on a fresh machine. Written
for an agent doing the setup; a human can follow it too.

The harness renders a paywall from a JSON file on disk through the real iOS layout
engine and re-renders whenever that file changes. You edit the JSON, the paywall
updates. Nothing is rebuilt between edits.

## What you get

| | |
|---|---|
| A resizable window running the real SDK | Mac Catalyst build of PaywallsTester |
| Load any dashboard paywall by URL | `scripts/loadpaywall` |
| Edit the loaded paywall in English | Claude Code, or `scripts/astraedit` |

## Prerequisites

- Xcode 26 or newer, with the Mac Catalyst SDK. `xcodebuild -version` should work.
- Python 3.9+.
- **mafdet CLI**, only if you want to load paywalls from the dashboard by URL.
  Installed through mise at RevenueCat; `mafdet auth login` to sign in. Skip this
  if you will supply JSON files by hand.
- A checkout of **RevenueCat/agents**, only if you want Astra to do the editing.
  Not needed otherwise.

## 1. Check out the SDK

The harness is a screen inside PaywallsTester, which lives in the `purchases-ios`
repo and builds the SDK from the same checkout. Pick the branch whose layout
engine you want to test.

```bash
git clone https://github.com/RevenueCat/purchases-ios.git
cd purchases-ios
git checkout <branch>
```

To compare two SDK branches side by side, use `git worktree add` rather than a
second clone. PaywallsTester references the SDK as a local package at `../../..`,
so each worktree builds its own SDK and the two stay independent.

## 2. Configure

Create `Local.xcconfig` at the repo root. It is gitignored.

```
REVENUECAT_API_KEY = appl_yourKeyHere
```

If the branch you are testing gates a feature behind a compilation condition, add
it here too. `Package.swift` reads this file and maps each token to a `.define(...)`:

```
SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(inherited) ENABLE_PAYWALL_MIN_MAX_SIZING
```

Caveat: the reader takes `CI.xcconfig` in preference to `Local.xcconfig`, so a
stray `CI.xcconfig` silently shadows everything here.

## 3. Build for Mac Catalyst

Catalyst is the point. `\.paywallWindowSize` is the paywall's rendered container,
not the device screen, so dragging the window edge is what drives window size
conditions and min/max rules. Simulators are fixed-size and cannot do this.

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

xcodebuild -project Tests/TestingApps/PaywallsTester/PaywallsTester.xcodeproj \
  -scheme 'PaywallsTester - SK config' \
  -destination 'platform=macOS,variant=Mac Catalyst' \
  -derivedDataPath .build-catalyst \
  CODE_SIGN_IDENTITY="-" CODE_SIGN_ENTITLEMENTS="" DEVELOPMENT_TEAM="" \
  build
```

Two things that will bite you:

- **The scheme is `PaywallsTester - SK config`.** There is no scheme named plain
  `PaywallsTester`; the others are `- Live Config` and `- macOS Focus Regression`.
- **Ad-hoc signing with the entitlements cleared is deliberate.** It also drops the
  app sandbox, which is what lets the app read a watch folder anywhere on disk
  without a folder-picker grant.

## 4. Run

```bash
env LIVE_PAYWALL_DIR="$PWD/paywall-live" \
  .build-catalyst/Build/Products/Debug-maccatalyst/PaywallsTester.app/Contents/MacOS/PaywallsTester
```

Launch the binary directly, not with `open`. `open` goes through LaunchServices
and the app inherits the launchd environment, so `LIVE_PAYWALL_DIR` never
arrives.

`LIVE_PAYWALL_DIR` is optional. Without it the app falls back to
`$SIMULATOR_HOST_HOME/rc/paywall-live` in the simulator, then to a folder you pick
through the `…` menu, remembered as a security-scoped bookmark.

`LIVE_PAYWALL_LABEL="whatever"` puts a badge in the popover, which is worth
setting when two builds are open at once and look identical.

### On an iOS simulator instead

```bash
SIMCTL_CHILD_LIVE_PAYWALL_DIR=$HOME/rc/paywall-live \
  xcrun simctl launch <device-udid> com.revenuecat.PaywallsTester
```

Environment variables must carry the `SIMCTL_CHILD_` prefix to reach the app.
`DEVELOPER_DIR` has to be exported in every shell or `xcrun simctl` is not found.

## 5. Load a paywall

```bash
scripts/loadpaywall "https://app.revenuecat.com/projects/<id>/paywalls/<pw…|wf…>/builder"
```

Both URL shapes work. `paywalls/pw…` is a single paywall, fetched with
`mafdet paywall components` plus `mafdet paywall localizations`. `paywalls/wf…` is
a workflow, fetched with `mafdet workflow steps|screen`; add `--list` to see its
screens and `--screen <id>` to pick one.

The script exists because the dashboard stores structure and copy separately and
every export path hands them over separately, so neither half renders alone. It
also fills in `template_name`, `asset_base_url` and `revision`, which no export
includes and whose absence makes the SDK fall back to the default template
*without reporting an error*.

Set `PAYWALL_LIVE_DIR` to write somewhere other than `<repo>/paywall-live`.

### Or drop files in by hand

Anything in the watch folder is picked up. Accepted shapes:

- a whole `PaywallComponentsData` document
- `{ "paywall": …, "ui_config": … }`
- a split mafdet export: copy in both `<id>-components.json` and
  `<id>-localizations.json`, then select the *components* one. The localizations
  half is paired by filename prefix automatically.

## 6. Edit it

**With Claude Code.** Point it at `paywall-live/live.json` and describe the change.
No credentials, no services. This is the path that works everywhere.

**With Astra.** Needs a checkout of `RevenueCat/agents`:

```bash
export ASTRA_DIR=/path/to/agents/packages/astra
cd "$ASTRA_DIR" && cp .env.template .env   # fill in model provider + keys
scripts/astraedit "cap the content at 600 and centre it"
```

`astraedit` seeds an eval case from the current `live.json`, runs one Astra turn,
prints a node-level diff of what changed, and writes the result back.

Two things to know about this route:

- It goes through the **eval harness**, not Astra's editor API. The editor endpoint
  requires a dashboard `rc_auth_token` cookie even against a local server, while
  eval cases declare their own `feature_flags` and `paywall_size` inline and need
  no credentials at all.
- **It needs one small addition to the agents repo**, described below. Make it by
  hand; it is twelve lines and a patch file would rot the first time that file
  moves.

### The agents change

The eval runner renders screenshots and writes a summary, but it never writes the
**paywall JSON** Astra produced, and that document is the whole point here. Without
this, `astraedit` runs Astra successfully and then exits saying Astra produced no
paywall.

In `packages/astra/evals/run_eval.py`, find `_run_single_eval_item`. Partway through
it computes the outgoing paywall:

```python
after_canonical = canonical_paywall_dump(evidence_after_paywall)
```

Immediately after that line, write the document to disk when an environment
variable asks for it:

```python
# Persist the outgoing paywall so it can be rendered natively in the iOS
# harness rather than only by the bundled web renderer.
if (_dump_dir := os.environ.get("EVAL_PAYWALL_DUMP_DIR")):
    import json as _json
    _out = Path(_dump_dir)
    _out.mkdir(parents=True, exist_ok=True)
    _slug = f"{payload['case_id']}-" + "".join(
        ch if ch.isalnum() else "-" for ch in payload["message"]
    )[:60]
    (_out / f"{_slug}.json").write_text(
        _json.dumps(after_canonical, indent=2) + "\n", encoding="utf-8"
    )
```

Three things worth knowing if you adapt it:

- **Gate it on the environment variable.** Unset, the runner behaves exactly as
  before, so this cannot affect a normal eval run or CI.
- **The filename must include the case id.** An earlier version keyed only on a
  field that does not exist on the payload, so every case in a run silently
  overwrote one file and only the last survived.
- `os` and `Path` are already imported in that module; only `json` needs the local
  alias, since the name is shadowed in that scope.

Each run is a fresh Astra conversation. Turns chain by re-seeding from the current
paywall rather than by session id, which is the trade-off the eval route makes.

## Reading a render correctly

- The harness draws exactly one thing on the paywall: the `…` button, bottom
  right. Everything else on screen belongs to the paywall, including any back
  chevron or close button.
- The paywall gets the whole window, so the container width equals the window
  width. There is no inset to subtract.
- `SizeConstraint.init(from:)` has a blanket catch that degrades a malformed size
  to `.fit`, so a typo in a size object surfaces as a layout oddity, never a
  decoding error.
- A Catalyst window will not go below roughly 500pt wide. Narrower cases need a
  simulator.

## Troubleshooting

| Symptom | Cause |
|---|---|
| Paywall renders as the default template | Missing `template_name` / `asset_base_url` / `revision`. `loadpaywall` adds them; a hand-dropped file may not have them. |
| `xcrun: error: missing DEVELOPER_DIR` | Not exported in this shell. It does not persist between invocations. |
| App ignores `LIVE_PAYWALL_DIR` | Launched via `open`. Run the binary inside the bundle instead. |
| mafdet fails with a 401 | Auth expires roughly hourly. `mafdet auth login`. |
| `UnicodeDecodeError` from a mafdet call | The CLI corrupts multi-byte characters at a 160 KiB stdout boundary. Always use `-o <file>`; `loadpaywall` already does. |
| Nothing reloads after an edit | The poll compares modification date and size. A same-size edit inside the same second can be missed. Use Reload in the `…` popover. |
| Split export shows an error until you hit Reload | Expected. Adding the localizations sibling does not change the components file, so the poll sees nothing. |
