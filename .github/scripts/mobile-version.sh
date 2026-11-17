#!/usr/bin/env bash
# Version and release-notes gate for the mobile workflows. Run from the repository root, before any build.
#
#   - The version is the one in mobile/pubspec.yaml (`version: 1.0.0-beta.2+1`, without the `+...` part).
#     Releases are named after it (tag mobile-v<version>), never after a build number.
#   - mobile/docs/release-notes/<version>.md must exist and say something, or the workflow stops here.
#   - The Android version code (the number Android uses to allow an update over an older install) is the
#     commit count on this branch, so it only ever goes up. Needs a full checkout (fetch-depth: 0).
#
# Writes version=, tag=, notes=, version_code= to $GITHUB_OUTPUT (or prints them when run by hand).
set -euo pipefail

pubspec=mobile/pubspec.yaml
raw=$(sed -n 's/^version:[[:space:]]*//p' "$pubspec" | tr -d '"'"'"' \r')
version=${raw%%+*}

# Semantic version: 1.2.3 or 1.2.3-beta.4 (the API stores at most 30 characters).
if ! [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z]+(\.[0-9A-Za-z]+)*)?$ ]] || [ ${#version} -gt 30 ]; then
  echo "::error file=$pubspec::'version: $raw' is not a release version. Use e.g. 'version: 1.0.0-beta.2+1'."
  exit 1
fi

notes="mobile/docs/release-notes/$version.md"
if [ ! -f "$notes" ]; then
  echo "::error file=$pubspec::No release notes for $version. Add $notes (what is new, what to test, known limits) before building."
  exit 1
fi
if ! grep -q '[^[:space:]]' "$notes" || [ "$(grep -c '[^[:space:]]' "$notes")" -lt 3 ]; then
  echo "::error file=$notes::$notes is empty. Describe this release before building."
  exit 1
fi

if [ "$(git rev-parse --is-shallow-repository)" = "true" ]; then
  echo "::error::Shallow checkout: the Android version code needs the full history (actions/checkout with fetch-depth: 0)."
  exit 1
fi
version_code=$(git rev-list --count HEAD)

out=${GITHUB_OUTPUT:-/dev/stdout}
{
  echo "version=$version"
  echo "tag=mobile-v$version"
  echo "notes=$notes"
  echo "version_code=$version_code"
} >> "$out"
echo "Mobile version $version (Android version code $version_code), notes: $notes"
