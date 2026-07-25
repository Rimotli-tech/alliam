"use strict";

const NEXT_200_STAGES = [
  {
    stage: 1,
    grade: "Grade 1",
    level: "Foundation",
    words: `
      clever gentle honest eager proud loyal timid vivid rapid sturdy fragile
      cheerful gloomy lonely kindly useful playful thankful hopeful careful
      fearless restless peaceful harmful helpful sudden secret silent strange
      famous distant narrow shallow smooth nimble seldom always perhaps almost
      enough early usually already towards beyond inside against among around
      between
    `,
  },
  {
    stage: 2,
    grade: "Grade 1",
    level: "Foundation",
    words: `
      answer believe breathe brought busy choose climb could country cousin
      decide different discover earth eight explain favourite forward friend
      guard heard heart height island laugh learn minute natural notice often
      people piece please question quiet quite ready reason receive remember
      straight though thought through together tongue trouble whole woman wonder
    `,
  },
  {
    stage: 3,
    grade: "Grade 2",
    level: "Builder",
    words: `
      ability absence accident admire amazing appear attention balance boundary
      capture celebrate centre certain complete consider continue create describe
      direction disappear electric energy excellent exercise familiar fortunate
      frequent improve include increase interest material memory mention message
      observe opposite ordinary particular possible prepare promise protect
      recognise regular surprise temperature terrible variety visible
    `,
  },
  {
    stage: 4,
    grade: "Grade 2",
    level: "Builder",
    words: `
      achievement advertisement aggressive amateur apparent argument arithmetic
      awkward category ceremony committee community competition curiosity definite
      desperate determined disastrous embarrass equipment especially existence
      experience fascinating government guarantee identity immediately independent
      individual intelligent interrupt leisure marvellous medicine neighbour
      opportunity physical popular position profession recommend relevant
      responsible sufficient thorough twelfth vegetable vehicle voluntary
    `,
  },
];

const NEXT_200_WORDS = NEXT_200_STAGES.flatMap((group) =>
  group.words.trim().split(/\s+/).map((word) => ({
    word,
    stage: group.stage,
    grade: group.grade,
    level: group.level,
  })),
);

if (NEXT_200_WORDS.length !== 200) {
  throw new Error(`Expected 200 approved words, found ${NEXT_200_WORDS.length}.`);
}

module.exports = { NEXT_200_WORDS };
