# Bundled alphabet release process

Flutter bundles the approved recorded letter names so spelling does not require
26 Storage requests.

## Current versions

- Firestore manifest: `audioVersions/alliam-alphabet-v2`
- Firebase source: `alliam-alphabet-manual-v1`
- Flutter derivative: `alliam-alphabet-bundle-v1`
- Flutter paths: `assets/audio/letters/a.mp3` through `z.mp3`

Firebase remains the versioned source of truth. The bundled files are a
lightweight, normalized derivative of the approved manual source. If Firestore
reports a newer `sourceVersion`, Flutter uses the remote manifest until a new
app bundle containing that version is released.

## Processing profile

The current bundle was produced locally without speech generation or cloud
audio analysis:

- conservative leading and trailing silence removal at `-50 dB`
- approximately 25 ms of protected leading space
- approximately 140 ms of protected ending space
- loudness normalization to `-20 LUFS`
- true-peak ceiling of `-1.5 dB`
- mono, 44.1 kHz, 64 kbps MP3

All 26 outputs decode successfully. Their durations range from 0.368 to 1.001
seconds and their combined size is under 170 KB.

## Updating the bundle

1. Approve and install a complete 26-file manual alphabet through the
   JavaScript Admin audio workflow.
2. Assign a new immutable Firebase source version.
3. Copy the approved source files into a release workspace.
4. Apply the same conservative processing profile.
5. Verify all 26 files decode, are non-empty, and contain one letter name.
6. Update `BundledAlphabetManifest.sourceVersion` and `bundleVersion`.
7. Replace all files under `assets/audio/letters/`.
8. Run the audio tests, Flutter analysis, web build, and Android playback QA.
9. Release the Flutter application only after the Firebase manifest and bundle
   versions agree.

Never silently replace files without changing the bundle version. Corrected
recordings must use a new Firebase source version so persistent word and letter
caches cannot retain obsolete audio.
