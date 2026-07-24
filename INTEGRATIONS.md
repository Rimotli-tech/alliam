# Alliam service integration guide

The app is split into three independent systems. Keep these boundaries even if the vendors change later.

## 1. Audio library — ElevenLabs + Firebase Storage

Audio should be generated during a controlled library-building process, not during a child's session.

1. A team member imports or approves a word and its metadata.
2. A protected backend job sends approved scripts to ElevenLabs.
3. The job creates separate assets for normal pronunciation, slow pronunciation, letter sequence, definition, example sentence, origin, part of speech, and prompts where required.
4. A reviewer listens, supplies a pronunciation override if needed, and approves the version.
5. Approved files are uploaded to Firebase Storage and their URLs/version are written to Firestore.
6. The app preloads and plays those files during sessions.

Never place an ElevenLabs secret key in this browser application. Call ElevenLabs only from a protected Cloud Function or another trusted server.

Suggested Storage layout:

```text
audio/{voiceVersion}/{wordId}/pronunciation.mp3
audio/{voiceVersion}/{wordId}/pronunciation-slow.mp3
audio/{voiceVersion}/{wordId}/spelling.mp3
audio/{voiceVersion}/{wordId}/definition.mp3
audio/{voiceVersion}/{wordId}/sentence.mp3
audio/{voiceVersion}/{wordId}/origin.mp3
audio/{voiceVersion}/{wordId}/part-of-speech.mp3
```

## 2. Recognition — Microsoft Azure AI Speech

Use Azure Speech only during the child's attempt. The client captures a short utterance, recognition returns text, and `services.js` normalizes spoken letter names such as “bee” to `B`.

Recommended production pattern:

1. The signed-in app requests a short-lived Speech authorization token from a protected Firebase Cloud Function.
2. The app opens recognition only after the reveal audio has finished.
3. Partial results animate the active box but do not score it.
4. Stable/final letter results are normalized and passed into the same spelling state machine used by keyboard input.
5. Low-confidence results ask the learner to repeat; they should not be scored as wrong.
6. Recognition closes immediately when the word ends, the learner exits, or the timer expires.

Never ship an Azure subscription key in the app. Keep keyboard entry available for noisy rooms, permissions failures, accents the recognizer struggles with, and accessibility.

## 3. Product backend — Firebase

Use Firebase Authentication for parent/coach accounts and learner profiles underneath them. Use Firestore for durable product data, Realtime Database or Firestore listeners for match state, Storage for audio, and Cloud Functions for secrets and authoritative scoring.

Suggested collections:

```text
accounts/{accountId}
accounts/{accountId}/learners/{learnerId}
words/{wordId}
wordSets/{setId}
audioVersions/{versionId}
sessions/{sessionId}
matches/{matchId}
matches/{matchId}/rounds/{roundId}
leaderboards/{seasonId}/entries/{learnerId}
teams/{teamId}
tournaments/{tournamentId}
```

Security and fairness rules:

- Clients may submit attempts, but ranked scoring and rating changes must be calculated server-side.
- Send the next competition word only when the round begins; do not download a full ranked word list in advance.
- Store audit data for ranked rounds: timings, requests used, recognizer result, normalized spelling, and outcome.
- Treat learner profiles as child data: collect the minimum, default to private, and make deletion/export easy.
- Put parent consent, age handling, retention, and regional child-privacy requirements into the production release checklist.

## Connection order

1. Create the Firebase project, environments, Authentication providers, Firestore, Storage, and Functions.
2. Replace the local persistence methods in `services.js` with Firebase implementations.
3. Build the first approved ElevenLabs word pack and upload it to Storage.
4. Connect audio URLs to the existing playback adapter and verify asset preloading/fallback behavior.
5. Add the Azure Speech SDK and short-lived-token Cloud Function.
6. Route recognized letters through the existing keyboard-compatible input function.
7. Replace local match simulation with server-authoritative matchmaking and round state.
8. Add analytics, crash reporting, abuse controls, accessibility testing, and release monitoring.

The current `config.js` values are intentionally non-secret placeholders. Production web configuration may contain Firebase's public client configuration, but provider secret keys must remain server-side.
