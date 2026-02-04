# Release Checklist

## Pre-release
- Ensure tests pass on Ruby 3.1, 3.2, 3.3
- Update CHANGELOG.md with release notes
- Verify README and docs reflect the current API
- Confirm gemspec metadata (homepage, authors, email)

## Release
- Tag release in git (e.g., v0.1.0)
- Build gem: `gem build rubyrana.gemspec`
- Push gem: `gem push dist/rubyrana-0.1.0.gem`

## Post-release
- Update any version references
- Announce the release
