# Alliam learner journey and progression

## Current product decision

Alliam resumes a learner at the appropriate learning stage, not at an exact
word. Individual words remain evidence: missed words enter review, completed
words contribute to accuracy, and each completed session contributes to a
grade-specific pathway.

The initial Grade 1 pathway is:

1. Foundation
2. Builder
3. Champion

Automatic progression is the default. A learner or account owner may disable it
in Settings and manually select Foundation, Builder, or Champion. Manual
selection controls the difficulty served in training without deleting the
learner's recorded journey, scores, or earned pathway progress. Re-enabling
automatic progression resumes from the recorded pathway stage.

The stage list is data-shaped and ordered, so intermediate stages can be added
later without changing historic session records.

## Promotion rules (initial calibration)

- Foundation: at least 5 completed sessions and 80% stage accuracy.
- Builder: at least 8 completed sessions and 85% stage accuracy.
- Champion: terminal for the current pathway; its metrics continue to accrue.

These values are initial calibration, not final pedagogy. A promotion occurs
only at session completion.

## Durable records

Each learner has:

- `journey.stage`
- `journey.stageLabel`
- `journey.stageSessions`
- `journey.stageAccuracy`
- `journey.sessions`
- `journey.wordsPractised`
- `journey.accuracy`
- `journey.totalScore`
- `journey.reviewWords`
- `journey.lastMode`
- `journey.lastCompletedAt`

Every completed session is also appended beneath:

`accounts/{accountId}/learners/{learnerId}/sessions/{sessionId}`

The session record contains mode, correct and attempted counts, accuracy,
score earned, missed words, stage, promotion status and completion time.

## Milestones and payoff

A configured session (five words by default) is one milestone unit. Completion
shows accuracy, score earned, pathway position and promotion status. The
payoff screen is intentionally separate from per-word correctness feedback.

## Deferred decisions

- Additional stages between Foundation, Builder and Champion.
- Whether promotion accuracy should use the full stage, a rolling window, or
  mastery by word family.
- Grade-to-grade promotion.
- Mode weighting and assistance penalties.
- Adaptive word-set selection.
- Final score economy and competitive rating relationship.

Those decisions can evolve without rewriting the stored session evidence.
