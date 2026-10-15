#!/usr/bin/env bash
#
# Bumps the app version from Conventional Commits and updates pubspec.yaml and
# CHANGELOG.md. The GitHub Actions workflow commits, tags and releases.
#
# Usage:
#   scripts/bump_version.sh [auto|patch|minor|major]
#
#   auto (default) looks at the commit messages since the last vX.Y.Z tag:
#     - "feat!:" or "BREAKING CHANGE"  -> major
#     - "feat:"                        -> minor
#     - "fix:"                         -> patch
#     - anything else                  -> no release
#
# Environment:
#   FORCE=1     treat "no release" as a patch bump (used by manual runs)
#   GITHUB_OUTPUT  when set, the results are written there as step outputs.
#
set -euo pipefail

PUBSPEC="pubspec.yaml"
CHANGELOG="CHANGELOG.md"
BUMP="${1:-auto}"
FORCE="${FORCE:-0}"

emit() {
  # $1 key, $2 value
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "$1=$2" >> "$GITHUB_OUTPUT"
  fi
  echo "$1=$2"
}

current=$(grep -E '^version:' "$PUBSPEC" | head -1 | awk '{print $2}')
full_version="${current%%[[:space:]]*}"
version="${full_version%%+*}"
build="${full_version#*+}"
[ "$build" = "$version" ] && build=0

IFS='.' read -r major minor patch <<< "$version"
major=${major:-0}; minor=${minor:-0}; patch=${patch:-0}

last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -n "$last_tag" ]; then
  range="${last_tag}..HEAD"
else
  range="HEAD"
fi
commits=$(git log --pretty=format:'%s' "$range" 2>/dev/null || true)

if [ "$BUMP" = "auto" ]; then
  if printf '%s\n' "$commits" | grep -qE '^[a-zA-Z]+(\(.*\))?!:' || \
     printf '%s\n' "$commits" | grep -q 'BREAKING CHANGE'; then
    BUMP=major
  elif printf '%s\n' "$commits" | grep -qE '^feat(\(.*\))?:'; then
    BUMP=minor
  elif printf '%s\n' "$commits" | grep -qE '^fix(\(.*\))?:'; then
    BUMP=patch
  else
    if [ "$FORCE" = "1" ]; then
      BUMP=patch
    else
      echo "No feature/fix commits since ${last_tag:-the first commit}; nothing to release."
      emit released false
      exit 0
    fi
  fi
fi

case "$BUMP" in
  major) major=$((major + 1)); minor=0; patch=0 ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  patch) patch=$((patch + 1)) ;;
  *) echo "Unknown bump type: $BUMP" >&2; exit 1 ;;
esac

build=$((build + 1))
new_version="${major}.${minor}.${patch}"
new_full="${new_version}+${build}"
tag="v${new_version}"
today=$(date +%Y-%m-%d)

# Update pubspec.yaml (the single source of truth for the version).
awk -v v="$new_full" '
  /^version:/ && !done { print "version: " v; done=1; next }
  { print }
' "$PUBSPEC" > "$PUBSPEC.tmp" && mv "$PUBSPEC.tmp" "$PUBSPEC"

# Prepend a changelog section built from the commit messages.
entries=$(printf '%s\n' "$commits" | grep -vE '^\s*$' | sed 's/^/- /')
if [ -z "$entries" ]; then
  entries="- Maintenance release."
fi
tmp=$(mktemp)
{
  echo "## ${new_version} — ${today}"
  echo
  printf '%s\n' "$entries"
  echo
  if [ -f "$CHANGELOG" ]; then
    cat "$CHANGELOG"
  fi
} > "$tmp"
mv "$tmp" "$CHANGELOG"

emit released true
emit version "$new_version"
emit tag "$tag"
echo "Bumped $full_version -> $new_full ($tag)"
