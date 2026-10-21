# PullOver X 1.7.4

This source update adds an opposite-edge handle. Either handle can be held and
dragged to the center search target; releasing there opens an installed-app
picker. Results match app names and bundle identifiers and use
`pinAppWithBundleId:` to open inside PullOver X. Double tap retains the existing
fullscreen action.

The opposite handle follows the primary handle's vertical position and existing
size/opacity settings. Its horizontal swipe opens or closes the panel.

Search owns window input while visible and restores the previous key window on
cancel, selection, or transient-interface cleanup.

## Validation

- `git diff --check` passed.
- This update has not been compiled or tested on a device.
- Windows WSL enumeration fails with E_ACCESSDENIED in this environment.
- GitHub CLI device authorization has been completed.
- No new deb has been produced; old binaries are not included in this update.

After compilation, validate on the target device:

1. Both edge handles receive taps and double taps in portrait and landscape.
2. Hold either handle, drag to center, and release to open search.
3. Releasing outside the target or cancelling a gesture does not open search.
4. Search by name and bundle ID; selecting a result opens in the hosted window.
5. Cancel, rotate, and lock while searching; verify keyboard/input cleanup.
6. Verify left-handed mode, handle opacity, handle size, and position lock.

## Build

The existing GitHub Actions workflow runs on pushes to main/master and uploads
separate roothide, rootless, and rootful artifacts. The workflow is unchanged;
its release job may require the repository's workflow write permission.

For a configured macOS/Xcode/Theos environment:

```sh
bash build.sh roothide release
```

Use the resulting `iphoneos-arm64e.deb` for the requested roothide target only
after successful compilation and inspection. The earlier reported SpringBoard
failure has no confirmed diagnosis; these changes do not establish its cause.
