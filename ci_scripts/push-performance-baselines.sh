#!/bin/bash
set -euo pipefail

branch="${CIRCLE_BRANCH:?CIRCLE_BRANCH is required}"
revision="${CIRCLE_SHA1:?CIRCLE_SHA1 is required}"
baseline="Tests/PerformanceTests/Baselines.json"

if [[ "$branch" == "main" || -n "${CIRCLE_TAG:-}" ]]; then
    echo "Baseline updates require a PR branch."
    exit 1
fi

git check-ref-format "refs/heads/$branch"
git fetch origin "refs/heads/$branch"
if [[ "$(git rev-parse FETCH_HEAD)" != "$revision" || "$(git rev-parse HEAD)" != "$revision" ]]; then
    echo "The PR branch changed. Run record-performance again."
    exit 1
fi

if git diff --quiet HEAD -- "$baseline"; then
    echo "No baseline changes to commit."
    exit 0
fi

git commit --only -m "Update performance baselines" -- "$baseline"
git push origin "HEAD:refs/heads/$branch"
