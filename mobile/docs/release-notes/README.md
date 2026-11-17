# Release notes

One file per app version, named after the version: `1.0.0-beta.2.md`. The mobile build workflows
(`Mobile build`, `Mobile iOS build check`) stop before building when the version in
`mobile/pubspec.yaml` has no file here (`.github/scripts/mobile-version.sh`).

## Releasing a new version

1. Raise `version:` in `mobile/pubspec.yaml`, e.g. `1.0.0-beta.2+1` to `1.0.0-beta.3+1`. The part after `+` is
   not used: CI sets the Android version code from the commit count so it always goes up.
2. Add `mobile/docs/release-notes/1.0.0-beta.3.md`: what is new, what to test, known limits, and anything the
   FCU team must do first (for example a server update). Write it for testers, not developers.
3. Commit both together and push to `main`.
4. Actions > **Mobile build** > Run workflow > tick **Publish**. It builds Android and iPhone, then makes one
   release tagged `mobile-v1.0.0-beta.3`, titled "FCU app 1.0.0-beta.3", with the notes as its text and two
   files: `fcu.apk` (Android) and `fcu-1.0.0-beta.3-unsigned.ipa` (iPhone, to sideload). If either build
   fails, nothing is published. Installed Android apps compare their version with it and offer the update.

A version is released once. To fix something after publishing, raise the version again.

Versions follow semantic versioning: `1.0.0-beta.2` < `1.0.0-beta.10` < `1.0.0-rc.1` < `1.0.0` < `1.0.1`.
