#!/usr/bin/env python3
"""Render SDK config benchmark JSONL results as a markdown table.

Usage:
    python3 compare.py results.jsonl                       # one file: summary table
    python3 compare.py baseline.jsonl candidate.jsonl      # two files: side-by-side with deltas

Rows are grouped by (mode, scenario, profile, loss_percent). When comparing, groups present
in only one file are shown with the other side empty.
"""

import json
import sys


KEY_FIELDS = ("mode", "transport", "scenario", "profile", "loss_percent",
              "paywalls", "workflows", "seed")
METRICS = ("p50_ms", "p95_ms", "request_count_mean", "bytes_received_mean")


def load(path):
    rows = {}
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            row = json.loads(line)
            key = tuple(row.get(field) for field in KEY_FIELDS)
            if key in rows:
                raise SystemExit(f"{path}: duplicate row for {dict(zip(KEY_FIELDS, key))}")
            rows[key] = row
    return rows


def fmt(value):
    if value is None:
        return "-"
    if isinstance(value, float):
        return f"{value:,.1f}"
    return f"{value:,}"


def delta(base, cand):
    if base in (None, 0) or cand is None:
        return "-"
    change = (cand - base) / base * 100
    return f"{change:+.0f}%"


def print_single(rows):
    header = list(KEY_FIELDS) + list(METRICS) + ["errors"]
    print("| " + " | ".join(header) + " |")
    print("|" + "---|" * len(header))
    for key in sorted(rows, key=str):
        row = rows[key]
        cells = [str(part) for part in key]
        cells += [fmt(row.get(metric)) for metric in METRICS]
        cells.append(str(row.get("error_count", 0)))
        print("| " + " | ".join(cells) + " |")


def post_warmup_errors(row):
    return row.get("post_warmup_error_count", row.get("error_count"))


def errors_cell(row):
    """Rows with post-warmup errors are not valid comparison input; make that loud."""
    errors = post_warmup_errors(row)
    if errors is None:
        return "-"
    return f"⚠️ {errors}" if errors else "0"


def print_comparison(baseline, candidate):
    header = list(KEY_FIELDS)
    for metric in ("p50_ms", "p95_ms"):
        header += [f"{metric} base", f"{metric} cand", "Δ"]
    header += ["req base", "req cand", "bytes base", "bytes cand", "err base", "err cand"]
    print("| " + " | ".join(header) + " |")
    print("|" + "---|" * len(header))

    invalid = 0
    for key in sorted(set(baseline) | set(candidate), key=str):
        base, cand = baseline.get(key, {}), candidate.get(key, {})
        cells = [str(part) for part in key]
        for metric in ("p50_ms", "p95_ms"):
            cells += [
                fmt(base.get(metric)),
                fmt(cand.get(metric)),
                delta(base.get(metric), cand.get(metric)),
            ]
        cells += [
            fmt(base.get("request_count_mean")),
            fmt(cand.get("request_count_mean")),
            fmt(base.get("bytes_received_mean")),
            fmt(cand.get("bytes_received_mean")),
            errors_cell(base),
            errors_cell(cand),
        ]
        if any(post_warmup_errors(row) for row in (base, cand) if row):
            invalid += 1
        print("| " + " | ".join(cells) + " |")

    if invalid:
        print(
            f"\n**⚠️ {invalid} row(s) have post-warmup errors; "
            "their timing deltas are not valid comparison input.**"
        )


def main(argv):
    if len(argv) == 2:
        print_single(load(argv[1]))
    elif len(argv) == 3:
        print_comparison(load(argv[1]), load(argv[2]))
    else:
        print(__doc__, file=sys.stderr)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
