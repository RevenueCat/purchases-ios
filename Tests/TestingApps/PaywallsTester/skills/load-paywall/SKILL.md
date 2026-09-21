---
name: load-paywall
description: >
  Render a real RevenueCat paywall natively in the live iOS harness from a
  builder URL or exported JSON, bringing the Mac Catalyst window up if it is not
  already running, then change it through Astra and watch it reload. Use when
  asked to "load this paywall", "show this in the simulator", "render this
  natively", "check how this looks on a tablet", or when a dashboard URL or a
  mafdet export is handed over and the point is to see it on a device rather
  than in the web renderer. Use it again for every follow-up request to change a
  paywall already loaded in the harness ("add padding", "cap the width",
  "centre the content"), which means running it through Astra rather than
  editing the JSON by hand.
---

# Load a paywall into the native harness

The harness renders dashboard paywall JSON through the real iOS layout engine, so
it shows what ships rather than what the web renderer draws. It lives in
PaywallsTester, on the `vinh/harness-minmax-fill` branch of `purchases-ios`.

Setup for a fresh machine is in `INSTALL.md` next to this file. This skill is the
day-to-day path once that is done. Commands below are relative to the repo root;
`$REPO` means wherever `purchases-ios` is checked out.

## Load and show

```bash
cd "$REPO"
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
Tests/TestingApps/PaywallsTester/scripts/loadpaywall "<builder URL>"
```

Paste the URL exactly as copied; the `#ln=…&x=…` fragment is ignored. Both shapes
work: `paywalls/pw…` is a single paywall, `paywalls/wf…` is a workflow (add
`--list` to see its screens, `--screen <id>` to pick one).

This writes `paywall-live/live.json` and then makes sure it is on screen: if the
Catalyst app is already running it just reloads, otherwise the app is launched,
building it first if there is no build yet. `--no-launch` skips that.

The first build takes a few minutes and logs to `.catalyst-build.log`.

## Edit it

**Once a paywall is loaded, treat any follow-up request to change it as a request
to run it through Astra**, not to hand-edit the JSON. "Add padding", "cap it at
600", "centre the content" and so on all mean:

```bash
cd "$REPO"
Tests/TestingApps/PaywallsTester/scripts/astraedit "<the user's request, verbatim>"
```

You are driving the harness; Astra is what edits the paywall. That indirection is
the point: the harness exists to watch what Astra authors meet the real iOS layout
engine, because Astra judges its own work against the bundled *web* renderer and
the two can disagree. Editing the JSON yourself tests only your own reading of the
schema, which is not what the user is looking at.

`astraedit` seeds a fresh eval case from the current `live.json`, runs one Astra
turn, prints a node-level diff, and writes the result back. The app reloads within
~300ms. Pass the request through as the user phrased it; do not translate it into
schema terms first, since how Astra interprets plain language is part of what is
being tested.

Then **report what changed in the document**, path with before and after values,
not just what you did. A screenshot does not say which property caused a layout
change. `astraedit` prints exactly this; relay it. On a restructure touching
thousands of nodes, summarise the handful that matter and give the total.

`--size 834x1194` sets the viewport Astra reasons about, `--dry-run` shows the
diff without writing.

Writing `$REPO/paywall-live/live.json` yourself is the fallback: when Astra is not set
up (`astraedit` says so and exits), when the user explicitly asks for a specific
JSON edit, or when constructing a probe to test a rule rather than a design.

## Screenshotting it

The Catalyst window is the one to capture, since it is freely resizable and
`\.paywallWindowSize` measures the paywall's container rather than the screen.

```bash
PID=$(pgrep -f 'Debug-maccatalyst/PaywallsTester.app/Contents/MacOS' | head -1)
osascript -e "tell application \"System Events\" to set frontmost of first process whose unix id is $PID to true"
B=$(osascript -e "tell application \"System Events\" to tell (first process whose unix id is $PID) to get {position, size} of front window")
# then: screencapture -x -R<x>,<y>,<w>,<h> out.png
```

Activate the app first. `screencapture -R` grabs whatever is on top of that
screen region, so without it you capture whatever window happens to be in front,
which may be the user's own content.

## Reading a render correctly

- The harness draws exactly one thing: the `…` button, bottom right. Everything
  else on screen belongs to the paywall, including back chevrons and close
  buttons.
- The paywall gets the whole window, so container width equals window width.
- This branch is **Fill-only min/max** (PR #7770). Clamps on `fit` sizes are
  silently dropped, so `{"type": "fit", "max": 300}` renders uncapped with no
  warning. The backend and Astra both accept clamps on `fit`, so a cap can simply
  not exist here. Do not read that as a layout bug.
- A Catalyst window will not go below ~500pt wide. Narrower cases need a
  simulator.
- A render that falls back to the default template means `template_name`,
  `asset_base_url` or `revision` is missing. Decoding reports this in `errorInfo`
  rather than failing. `loadpaywall` fills them in; a hand-dropped file may not
  have them.

## Gotchas

- `DEVELOPER_DIR` must point at your Xcode and be exported in every shell or `xcrun`/`xcodebuild` is not
  found. It does not persist between tool calls.
- mafdet auth expires roughly hourly; `mafdet auth login` on a 401.
- Never route mafdet output through stdout. The CLI corrupts multi-byte
  characters at a 160 KiB chunk boundary; `loadpaywall` uses `-o <file>`.
- Launch the app binary directly, never `open` the bundle. `open` goes through
  LaunchServices and the app never sees `LIVE_PAYWALL_DIR`.
