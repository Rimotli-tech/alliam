# Alliam UI / Audio Alignment Audit

Audit date: 2026-07-26

This document is the shared baseline for the UI task and the Audio-Gen task.
It records the repository state that was inspected, the current product
boundaries, and the file-level ownership rules needed to prevent conflicting
changes.

## Executive status

- The learner product is now a Flutter application in `alliam_app/`.
- The public landing page and operational Admin/audio tools remain in the
  JavaScript web application at the repository root.
- Both applications share Firebase project `spelliam-ad3fd`. The public product
  name is Alliam; the legacy Firebase project ID does not need to be renamed.
- The committed and deployed baseline is commit `937b80c`.
- The shared worktree contains substantial uncommitted Flutter, Firebase
  Functions, rules, index, and test work. That work is not yet represented by
  the production deployment.
- No bundled A-Z alphabet library is declared in Flutter's `pubspec.yaml`.
  Flutter still resolves all alphabet recordings from Firebase at runtime.
- Music and interface sound effects are bundled with Flutter and play locally.
- Word pronunciations are read from Firestore metadata and streamed from
  Firebase Storage.

## Current application surfaces

### JavaScript web application

Current responsibilities:

- Public landing page and links into the Flutter application
- Operational Admin experience
- Word library management
- ElevenLabs generation and regeneration controls
- Audio approval and manual alphabet upload
- Audio release inspection

This surface is not the canonical learner application and should not receive
new learner-facing UI or training mechanics.

### Flutter learner application

Registered routes:

- `/` — authentication gate, sign-in, sign-up, and onboarding
- `/home` — learner or account-owner Home
- `/train` — training-mode selection
- `/train/session/:mode` — focused training environment
- `/compete` — competition-mode selection and waiting-room entry
- `/rankings` — rankings
- `/social` — friends and teams
- `/profile` — account-owner profile/family area
- `/profile/learner/:id` — learner journey profile
- `/settings` — global settings

The organiser/Competition Organisation product is documented but has not yet
been implemented.

## Current feature state

### Authentication and profiles

- Firebase email/password authentication is implemented.
- Student, parent, and school onboarding branches exist.
- Parent accounts can own and switch between multiple learners.
- Account-owner and learner-profile separation is implemented in the Flutter
  data model.
- Normalized learner documents are written under
  `accounts/{uid}/learners/{learnerId}`.
- Legacy account state remains in `accounts/{uid}/data/app-state` for backward
  compatibility. The backend is therefore transitional, not fully normalized.

### Training

Sixteen mode identities are present in Flutter:

- Hear & Spell
- Word Flash
- Timed Drill
- Listen & Spell
- Missing Letters
- Pattern Drill
- Similar Words
- Build the Word
- Mock Bee
- Survival Run
- Streak Challenge
- Recall Ladder
- Daily Challenge
- Theme Challenge
- Reverse Spell
- Missed Words

Hear & Spell, Word Flash, Timed Drill, and the recently differentiated Missing
Letters, Pattern Drill, Similar Words, and Build the Word contain distinct
interaction logic. The remaining modes have varying amounts of shared
scaffolding and require product-specific completion and QA before being called
release-ready.

Training completion is dual-written to the legacy account-state document and
to normalized learner session documents.

### Competition

- Casual queue and private-room entry exist.
- Match assignment, match documents, round submission, and results exist.
- The local worktree adds queue cancellation, private-room cancellation,
  presence heartbeats, disconnect claims, and explicit forfeits.
- The above waiting-room and disconnect work is not yet deployed.
- Teams, schools, tournament operations, and Competition Organisation are not
  complete learner-facing competition flows.

### Rankings and social

- Flutter Rankings and Friends & Teams pages exist in the local worktree.
- Player bootstrap, friend requests, friendships, teams, events, and
  invitations are backed by callable Firebase Functions.
- These additions are not yet deployed from the current worktree.

### Settings

- A Firestore-backed global preference repository exists in the local
  worktree.
- Preferences live at `accounts/{uid}/settings/preferences`.
- Module-specific settings are not yet modeled as a complete independent
  settings hierarchy.

### Tests

- Flutter static analysis and unit/widget tests pass on this audited worktree.
- JavaScript syntax checks pass for `functions/index.js`, `app.js`, and
  `services.js`.
- A source scan found no embedded private keys, ElevenLabs secrets, or Azure
  secrets. Firebase's client configuration remains intentionally public.
- Emulator-backed critical-flow coverage was added for auth, onboarding,
  learner switching, training completion, and two-player match infrastructure.
- Portable Microsoft OpenJDK 21.0.12 is installed at
  `D:\codex_tools\jdk21\jdk-21.0.12+8` for Firebase tooling.
- The emulator suite passes on the attached Android device for auth, parent
  onboarding, learner switching, normalized training completion, private-room
  cancellation, queue cancellation, authoritative forfeit, and legacy student,
  parent, and school migration.
- Production must not be used as the integration-test target.

## Audio architecture observed

### Bundled Flutter audio

The following are local Flutter assets:

- Background soundtrack
- Module-entry sound
- Correct-answer sound
- Back-navigation sound
- Countdown beep
- Three key sounds
- Wrong-answer sound
- Word-entry sound
- Next-word sound

They are orchestrated by:

- `lib/core/audio/background_music_service.dart`
- `lib/core/audio/sound_effects_service.dart`

### Remote learning audio

Word audio:

- Firestore document: `words/{wordId}`
- Metadata field: `audio.{kind}.storagePath`
- Storage path family: `audio/{version}/{word}/{kind}.mp3`
- Flutter currently requires an approved primary pronunciation to load a word.

Alphabet audio:

- Firestore document: `audioVersions/alliam-alphabet-v2`
- Metadata field: `alphabet.{letter}.storagePath`
- The installed manual library points to
  `audio/alliam-alphabet-manual-v1/alphabet/{letter}.mp3`.
- Flutter loads the manifest lazily and streams each file from Storage.
- Download URLs are cached in memory only for the current service instance.

Playback:

- Word and letter playback use separate short-lived `AudioPlayer` instances.
- Letter spelling waits for each letter player to complete before advancing.
- Background music ducks during spoken learning audio.

### Audio generation and administration

Firebase Functions currently provide:

- Core audio-library generation
- Selected pronunciation regeneration
- Primary-pronunciation regeneration
- Approved next-200 pronunciation generation
- Core-library approval
- Generated alphabet creation
- Manual alphabet installation
- Azure Speech token issuance

These functions currently share `functions/index.js` with competition and
social functions. This is the largest code-conflict risk in the repository.

## Ownership contract

### UI task owns

- Flutter pages, widgets, responsive composition, navigation, and animations
- Theme tokens, typography, cards, shadows, icons, and visual feedback
- Keyboard, touch, pointer, focus, and accessibility behavior
- Training mechanics and user-visible state machines
- Competition screen flow and non-audio match behavior
- Auth, onboarding, profiles, rankings, friends, teams, and settings UI
- Domain repositories that do not define audio storage or playback
- UI and end-to-end acceptance tests

Primary UI-owned paths:

- `alliam_app/lib/app/`
- `alliam_app/lib/core/theme/`
- `alliam_app/lib/core/widgets/`
- `alliam_app/lib/features/**/presentation/`
- Non-audio feature repositories and models

### Audio-Gen task owns

- Audio generation, review, approval, correction, and release workflows
- ElevenLabs and pronunciation-dictionary behavior
- Recorded alphabet ingestion and validation
- Audio encoding, filenames, versioning, Storage paths, and manifests
- Flutter audio loading, caching, prewarming, and player implementation
- Bundled alphabet assets and audio-specific performance work
- Audio quality and playback sequencing tests
- JavaScript Admin audio tools

Primary Audio-Gen-owned paths:

- `alliam_app/lib/features/train/data/training_audio_service.dart`
- `alliam_app/lib/core/audio/`
- Flutter audio asset files
- Root JavaScript Admin audio controls
- Audio-specific Firebase Function modules once separated

### Shared contract files

Neither task should independently make broad changes to these files:

- `alliam_app/pubspec.yaml`
- `alliam_app/pubspec.lock`
- `alliam_app/lib/features/train/domain/spelling_word.dart`
- `alliam_app/lib/features/train/data/word_repository.dart`
- `alliam_app/lib/features/train/presentation/training_session_page.dart`
- `alliam_app/lib/features/compete/presentation/match_page.dart`
- `alliam_app/lib/main.dart`
- `functions/index.js`
- `firestore.rules`
- `storage.rules`
- `firebase.json`

Changes to a shared file require a small handoff containing:

1. Contract or behavior being changed
2. Exact file and symbols affected
3. New data shape, asset path, or method signature
4. Migration or compatibility impact
5. Acceptance test

## Required task split for every new direction

The UI task will return four sections whenever a direction crosses domains:

1. **UI work** — screens, interaction, state, and visual acceptance criteria
2. **Audio work** — a self-contained brief to forward to Audio-Gen
3. **Shared contract** — any schema, API, manifest, or lifecycle agreement
4. **Integration order** — which task lands first and how the result is tested

If there is no audio component, the UI task will explicitly say
`Audio-Gen: no work required`.

## Immediate conflict controls

1. Do not let both tasks edit `functions/index.js` concurrently.
2. Do not let both tasks edit `training_session_page.dart` concurrently.
3. Serialize `pubspec.yaml` and lockfile edits.
4. Audio-Gen may change playback internals, but UI owns when semantic playback
   actions are requested by the experience.
5. UI may call audio methods, but must not change Storage path conventions,
   manifest versions, generation settings, or encoding.
6. Audio-Gen must not alter layout, typography, animation, navigation, or
   training mechanics while integrating audio.
7. Before either task deploys, compare the worktree against the last deployed
   commit and run the full shared validation checklist.

## Recommended structural follow-up

Split `functions/index.js` without changing deployed function names:

- `functions/audio/`
- `functions/speech/`
- `functions/competition/`
- `functions/social/`
- `functions/shared/`

Introduce a narrow Flutter audio facade so UI code requests semantic actions
without depending on player or Storage details:

- prepare the application audio
- prepare a training session
- play a pronunciation
- spell a word
- play an interface effect
- enter or leave a focused exercise
- stop all transient playback

The Audio-Gen task owns the implementation. The UI task consumes the contract.

## Deployment baseline

- Root JavaScript site: Firebase Hosting site `spelliam-ad3fd`
- Flutter web app: Firebase Hosting site `alliam-app-ad3fd`
- Production currently reflects commit `937b80c`, not the full local worktree
- No production deployment should occur until the current UI/backend changes
  and Audio-Gen changes are reconciled and committed as an intentional release

## Current blockers and outstanding alignment work

- Reconcile the UI audit with Audio-Gen's independent audit.
- Land bundled/prewarmed alphabet work or confirm a different strategy.
- Split or lock the mixed-domain Functions entry point.
- Keep the JDK 21 emulator release-audit workflow in regular use.
- Verify the complete approved pronunciation library in Storage.
- Complete module-specific settings persistence.
- Finish and test the remaining training-mode mechanics.
- Deploy and validate the waiting-room/disconnect/forfeit implementation.
- Run browser, Android, and compact-web acceptance tests.
- Decide the first implemented slice of Competition Organisation.
