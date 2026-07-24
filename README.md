# Alliam

Alliam is a competition-first spelling product for learners, families, schools, and spelling-bee organizers. This repository contains the complete local product prototype for version 0.1.0. External providers are isolated behind service adapters so the app remains usable while those accounts are being configured.

The public entry route is `#landing`. It includes the responsive marketing homepage, routes existing learners into the application, and sends new learners into onboarding. The standalone transparent hero artwork is stored at `assets/alliam-abc-3d.png`.

## Included flows

- Role-based onboarding, learner profiles, demo access, and local persistence
- Home dashboard, notifications, progress, activity, and upcoming challenges
- Hear & Spell: full visual/audio demonstration followed by guided or strict spelling
- Word Flash: a three-second visual exposure followed by memory recall
- Timed Drill: one pronunciation and a strict 20-second attempt
- Mock Bee: hidden written word, strict submission, and formal information requests
- Missed Words: practice drawn from the learner's personal review queue
- Word reveal, normal/slow playback, letter demonstration, hidden attempt, per-letter feedback, and results
- Casual, ranked, private, and team competition lobbies with a local match simulator
- Information requests for definition, example sentence, origin, and part of speech
- Rankings, friends, teams, profiles, match history, and training history
- Parent dashboard, school hub, content manager, and tournament administration surfaces
- Experience, privacy, account, and external-service settings
- JSON progress export and local account reset

## Run locally

For the most reliable browser behavior, serve the folder rather than double-clicking `index.html`:

```powershell
python -m http.server 4173 --bind 127.0.0.1
```

Then open `http://127.0.0.1:4173`.

No installation or build step is required. Until Firebase is connected, state is stored in the browser. Until branded audio and speech recognition are connected, the app uses browser speech synthesis and its on-screen/physical keyboard.

## External services

Connection placeholders live in `config.js`. Provider boundaries live in `services.js`.

- Firebase: authentication, Firestore data, Cloud Functions, Storage audio URLs, presence, and real-time match state
- ElevenLabs: team-generated and approved voice assets; production clients should play stored audio rather than generate it during a learner session
- Microsoft Azure AI Speech: live recognition of spoken letter names and spelling commands

See `INTEGRATIONS.md` for the intended production architecture and connection sequence.

## Current boundary

The user experience and local product logic are functional. Multiplayer opponents, cross-device accounts, production audio, and cloud speech recognition are deliberately simulated or substituted until credentials and cloud resources are supplied.
