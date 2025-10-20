# Publishing Guide

This guide explains how to publish packages to pub.dev using the automated GitHub Actions workflow with official pub.dev integration.

## Overview

This project uses the **official pub.dev automated publishing** approach recommended by Dart team:
- 📖 [Official Documentation](https://dart.dev/tools/pub/automated-publishing)
- 🔐 No secrets needed - uses OIDC authentication
- 🏷️ Tag-based publishing - simple and secure
- 🤖 Fully automated process

## Prerequisites

### 1. Enable Automated Publishing on pub.dev

Before you can publish, you need to enable automated publishing for each package on pub.dev:

#### For `flutter_compositions`:

1. Go to https://pub.dev/packages/flutter_compositions/admin
2. Scroll to "Automated Publishing"
3. Click "Enable publishing from GitHub Actions"
4. Configure:
   - **Repository**: `yoyo930021/flutter_compositions`
   - **Tag pattern**: `v{{version}}`
5. Save settings

#### For `flutter_compositions_lints`:

1. Go to https://pub.dev/packages/flutter_compositions_lints/admin
2. Scroll to "Automated Publishing"
3. Click "Enable publishing from GitHub Actions"
4. Configure:
   - **Repository**: `yoyo930021/flutter_compositions`
   - **Tag pattern**: `v{{version}}`
5. Save settings

**Important**: The `{{version}}` placeholder will be replaced with the actual version from `pubspec.yaml`.

## Publishing Process

### Step 1: Update Versions

Update the version in both `pubspec.yaml` files:

```yaml
# packages/flutter_compositions/pubspec.yaml
version: 0.2.0  # Update to new version

# packages/flutter_compositions_lints/pubspec.yaml
version: 0.2.0  # Keep versions synchronized
```

### Step 2: Update CHANGELOGs

Add release notes to both CHANGELOG files:

```markdown
## [0.2.0] - 2025-01-15

### Added
- New feature X
- New composable Y

### Changed
- Updated API Z

### Fixed
- Bug fix A
```

### Step 3: Commit Changes

```bash
git add .
git commit -m "chore: release v0.2.0"
git push origin main
```

### Step 4: Create and Push Git Tag

```bash
# Create an annotated tag
git tag -a v0.2.0 -m "Release v0.2.0"

# Push the tag to GitHub
git push origin v0.2.0
```

### Step 5: Watch the Automation

1. GitHub Actions will automatically trigger when the tag is pushed
2. Go to **Actions** tab to watch the progress
3. The workflow will:
   - ✅ Publish `flutter_compositions` to pub.dev
   - ✅ Publish `flutter_compositions_lints` to pub.dev (after main package)
   - ✅ Create a GitHub Release with CHANGELOG content

## Workflow Details

### What Happens When You Push a Tag

The workflow (`.github/workflows/publish.yml`) performs these steps:

#### Job 1: Publish flutter_compositions

Uses official dart-lang reusable workflow:
- Validates `pubspec.yaml`
- Runs tests
- Publishes to pub.dev using OIDC authentication

#### Job 2: Publish flutter_compositions_lints

Same as Job 1, but waits for the main package to publish first.

#### Job 3: Create GitHub Release

- Extracts version from tag (removes 'v' prefix)
- Extracts CHANGELOG content for this version
- Creates GitHub Release with release notes
- Marks as prerelease if version contains '-' (e.g., `v1.0.0-beta`)

#### Job 4: Summary

- Provides a summary of all operations
- Links to published packages on pub.dev
- Links to GitHub Release

## Tag Pattern Examples

The workflow accepts these tag formats:

- `v1.0.0` - Stable release
- `v0.1.0` - Initial release
- `v1.0.0-beta` - Prerelease
- `v1.0.0-alpha.1` - Prerelease with build number
- `v2.0.0-rc.1` - Release candidate

**Important**: Tag must start with 'v' followed by semantic version.

## Version Strategy

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (1.0.0): Breaking changes
- **MINOR** (0.1.0): New features, backward compatible
- **PATCH** (0.0.1): Bug fixes, backward compatible

### Pre-releases:

- **Alpha** (`1.0.0-alpha`): Early development
- **Beta** (`1.0.0-beta`): Feature complete, testing
- **RC** (`1.0.0-rc.1`): Release candidate

## Release Checklist

Before creating a tag:

- [ ] Update version in both `pubspec.yaml` files
- [ ] Update both `CHANGELOG.md` files
- [ ] Run tests locally: `melos run test`
- [ ] Run analyze: `melos run analyze`
- [ ] Commit all changes
- [ ] Push to main branch
- [ ] Verify CI passes on main
- [ ] Create and push git tag
- [ ] Watch GitHub Actions workflow
- [ ] Verify packages on pub.dev
- [ ] Verify GitHub Release created
- [ ] Test installation: `flutter pub add flutter_compositions`

## Package Synchronization

### Why Keep Versions Synchronized?

Both packages should have the same version because:
- They're developed together in the same repository
- Changes often affect both packages
- Easier to track which versions work together
- Simpler for users to understand compatibility

### Publishing Both Packages

When you push a tag, both packages are published automatically:
1. `flutter_compositions` publishes first
2. `flutter_compositions_lints` publishes after main package succeeds
3. If either fails, the other won't publish

## Troubleshooting

### Error: Tag pattern doesn't match

```
Error: Tag pattern 'v{{version}}' doesn't match pushed tag 'v1.0.0'
```

**Cause**: pub.dev tag pattern misconfigured or pubspec version doesn't match

**Solution**:
1. Check pub.dev admin page for correct tag pattern
2. Ensure `pubspec.yaml` version matches tag (without 'v')
3. Tag: `v1.0.0` should match pubspec version: `1.0.0`

### Error: Automated publishing not enabled

```
Error: This package has not enabled automated publishing from GitHub Actions
```

**Solution**: Follow [Prerequisites](#1-enable-automated-publishing-on-pubdev) to enable automated publishing

### Error: Repository mismatch

```
Error: Repository 'owner/repo' doesn't match configured repository
```

**Solution**: Update repository name in pub.dev admin settings

### Error: Version already exists

```
Error: Version 1.0.0 already exists
```

**Solution**: Increment version number and create new tag

### Error: Tests failed

```
Error: Tests failed during publish
```

**Solution**:
1. Run tests locally: `melos run test`
2. Fix failing tests
3. Commit and push changes
4. Delete and recreate tag

## Deleting a Tag

If you need to delete a tag (before publishing):

```bash
# Delete local tag
git tag -d v1.0.0

# Delete remote tag
git push origin :refs/tags/v1.0.0
```

**Warning**: Once a package version is published to pub.dev, it **cannot be unpublished**!

## Post-Publication

After successful publication:

### 1. Verify Publication

- ✅ Check https://pub.dev/packages/flutter_compositions
- ✅ Check https://pub.dev/packages/flutter_compositions_lints
- ✅ Verify version numbers are correct
- ✅ Check pub.dev scores (should be 100+ points)

### 2. Test Installation

```bash
# Create a new Flutter project
flutter create test_app
cd test_app

# Add package
flutter pub add flutter_compositions
flutter pub add flutter_compositions_lints --dev

# Verify it works
flutter analyze
```

### 3. Update Documentation

- Update documentation site if needed
- Update example projects
- Post release notes on social media

### 4. Monitor

- Watch GitHub issues for problems
- Check pub.dev analytics
- Monitor CI/CD for main branch

## Security Considerations

### Tag Protection (Recommended)

Protect version tags to prevent accidental or malicious publishes:

1. Go to repository **Settings** → **Tags**
2. Click **Add rule**
3. Pattern: `v*`
4. Enable "Require a pull request before pushing"
5. Enable "Require approval before pushing"

### GitHub Environment (Optional)

Add an approval step for production releases:

1. Go to **Settings** → **Environments**
2. Create environment named `pub-dev`
3. Add required reviewers
4. Update workflow to use this environment

## Rolling Back

⚠️ **Important**: You cannot delete or unpublish a version from pub.dev!

If a bad version is published:

1. **Quick Fix**: Publish a new patch version with the fix
2. **Yanking**: Contact pub.dev team to yank the version (discouraged)
3. **Documentation**: Add notice in README about problematic version

Best practice: Always test with prereleases first!

## Testing Releases (Recommended)

Before stable release, test with prereleases:

```bash
# 1. Create prerelease version
# pubspec.yaml: version: 1.0.0-beta

# 2. Create prerelease tag
git tag -a v1.0.0-beta -m "Beta release"
git push origin v1.0.0-beta

# 3. Test the prerelease
flutter pub add flutter_compositions:1.0.0-beta

# 4. If OK, create stable release
# pubspec.yaml: version: 1.0.0
git tag -a v1.0.0 -m "Stable release"
git push origin v1.0.0
```

## Support

For issues:
- 📖 [Official pub.dev documentation](https://dart.dev/tools/pub/automated-publishing)
- 🐛 [GitHub Issues](https://github.com/yoyo930021/flutter_compositions/issues)
- 💬 [GitHub Discussions](https://github.com/yoyo930021/flutter_compositions/discussions)
