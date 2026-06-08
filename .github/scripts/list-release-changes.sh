#!/usr/bin/env bash
set -euo pipefail

# List commit subjects since the latest release tag (vX.Y.Z or vX.Y.Z-pN),
# excluding chore:, test:, and ci: commits.

latest_tag() {
	git tag -l 'v*' --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+(-p[0-9]+)?$' | head -1 || true
}

PREV_TAG="${1:-$(latest_tag)}"

if [[ -z "${PREV_TAG}" ]]; then
	echo "error: no release tag found (expected vX.Y.Z or vX.Y.Z-pN)" >&2
	exit 1
fi

echo "Changes since ${PREV_TAG}:" >&2
commits=$(git log "${PREV_TAG}..HEAD" --pretty=format:'%s' --no-merges)
if [[ -n "${commits}" ]]; then
	printf '%s\n' "${commits}" | grep -viE '^(chore|test|ci):' || true
fi
