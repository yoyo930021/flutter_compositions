#!/usr/bin/env bash
set -euo pipefail

# Release script for flutter_compositions monorepo.
# Bumps versions, updates changelogs, commits, and tags.
#
# Usage: ./scripts/release.sh <version>
# Example: ./scripts/release.sh 0.2.0

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

PUBSPECS=(
  "$REPO_ROOT/packages/flutter_compositions/pubspec.yaml"
  "$REPO_ROOT/packages/flutter_compositions_lints/pubspec.yaml"
)

CHANGELOGS=(
  "$REPO_ROOT/packages/flutter_compositions/CHANGELOG.md"
  "$REPO_ROOT/packages/flutter_compositions_lints/CHANGELOG.md"
)

#--- Helpers -------------------------------------------------------------------

die() { echo "Error: $*" >&2; exit 1; }

# Portable in-place sed (macOS vs GNU)
sedi() {
  if [[ "$OSTYPE" == darwin* ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

#--- Validation ----------------------------------------------------------------

VERSION="${1:-}"
[[ -z "$VERSION" ]] && die "Usage: $0 <version>  (e.g. 0.2.0 or 1.0.0-beta.1)"

# Validate semver (X.Y.Z or X.Y.Z-pre.N)
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+(\.[a-zA-Z0-9]+)*)?$ ]]; then
  die "Invalid version '$VERSION'. Expected semver format: X.Y.Z or X.Y.Z-pre.N"
fi

TAG="v$VERSION"

cd "$REPO_ROOT"

# Check clean working tree
if ! git diff --quiet || ! git diff --cached --quiet; then
  die "Working tree is not clean. Commit or stash your changes first."
fi

if [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
  die "There are untracked files. Commit or remove them first."
fi

# Check on main branch
BRANCH="$(git symbolic-ref --short HEAD)"
if [[ "$BRANCH" != "main" ]]; then
  die "Not on 'main' branch (currently on '$BRANCH'). Switch to main first."
fi

# Check tag doesn't exist
if git rev-parse "$TAG" >/dev/null 2>&1; then
  die "Tag '$TAG' already exists."
fi

#--- Update pubspec versions ---------------------------------------------------

echo "Updating pubspec versions to $VERSION..."
for pubspec in "${PUBSPECS[@]}"; do
  sedi "s/^version: .*/version: $VERSION/" "$pubspec"
  echo "  Updated $pubspec"
done

#--- Update changelogs ---------------------------------------------------------

TODAY="$(date +%Y-%m-%d)"
echo "Updating changelogs with [$VERSION] - $TODAY..."
for changelog in "${CHANGELOGS[@]}"; do
  sedi "s/^## \[Unreleased\]/## [Unreleased]\n\n## [$VERSION] - $TODAY/" "$changelog"
  echo "  Updated $changelog"
done

#--- Git commit & tag ----------------------------------------------------------

echo "Creating commit and tag..."
git add "${PUBSPECS[@]}" "${CHANGELOGS[@]}"
git commit -m "chore: release v$VERSION"
git tag "$TAG"

#--- Done ----------------------------------------------------------------------

echo ""
echo "Release v$VERSION prepared successfully!"
echo ""
echo "Review the changes:"
echo "  git log --oneline -1"
echo "  git diff HEAD~1"
echo ""
echo "When ready, push with:"
echo "  git push origin main --tags"
