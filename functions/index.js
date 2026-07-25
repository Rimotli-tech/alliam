"use strict";

const { onCall, onRequest, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const { NEXT_200_WORDS } = require("./approved-word-batches");

initializeApp();

// The value is entered with:
// firebase functions:secrets:set AZURE_SPEECH_KEY
// Never replace this declaration with the actual Azure key.
const AZURE_SPEECH_KEY = defineSecret("AZURE_SPEECH_KEY");
const ELEVENLABS_API_KEY = defineSecret("ELEVENLABS_API_KEY");
const ELEVENLABS_VOICE_ID = defineSecret("ELEVENLABS_VOICE_ID");

const AUDIO_REGION = "europe-west1";
const AUDIO_MODEL = "eleven_multilingual_v2";
const AUDIO_VERSION = "alliam-one-v1";
const ALPHABET_VERSION = "alliam-alphabet-v2";
const ALPHABET_PHONEMES = {
  a: "eɪ", b: "biː", c: "siː", d: "diː", e: "iː", f: "ɛf", g: "dʒiː",
  h: "eɪtʃ", i: "aɪ", j: "dʒeɪ", k: "keɪ", l: "ɛl", m: "ɛm", n: "ɛn",
  o: "oʊ", p: "piː", q: "kjuː", r: "ɑːr", s: "ɛs", t: "tiː", u: "juː",
  v: "viː", w: "ˈdʌbəljuː", x: "ɛks", y: "waɪ", z: "ziː", "z-zed": "zɛd",
};
const WORDS = [
  { word:"curious", level:"Foundation", definition:"Eager to know or learn something.", sentence:"The curious child examined the unusual shell.", origin:"Latin", part:"adjective" },
  { word:"journey", level:"Foundation", definition:"An act of travelling from one place to another.", sentence:"Their journey across the mountains took three days.", origin:"Old French", part:"noun" },
  { word:"whisper", level:"Foundation", definition:"To speak very softly.", sentence:"Please whisper while the baby is sleeping.", origin:"Old English", part:"verb" },
  { word:"courage", level:"Foundation", definition:"The ability to face fear or difficulty.", sentence:"She showed courage during the difficult challenge.", origin:"Old French", part:"noun" },
  { word:"precious", level:"Foundation", definition:"Greatly valued or deeply loved.", sentence:"The photograph was a precious family keepsake.", origin:"Latin", part:"adjective" },
  { word:"brilliant", level:"Foundation", definition:"Exceptionally clever, skilful, or impressive.", sentence:"His brilliant solution surprised the whole class.", origin:"French", part:"adjective" },
  { word:"mystery", level:"Foundation", definition:"Something difficult or impossible to explain.", sentence:"The missing footprint remained a mystery.", origin:"Greek", part:"noun" },
  { word:"rhythm", level:"Foundation", definition:"A repeated pattern of sound or movement.", sentence:"The drummer maintained a steady rhythm.", origin:"Greek", part:"noun" },
  { word:"ancient", level:"Foundation", definition:"Belonging to the very distant past.", sentence:"They discovered an ancient stone carving.", origin:"Latin", part:"adjective" },
  { word:"graceful", level:"Foundation", definition:"Moving in a smooth and elegant manner.", sentence:"The graceful dancer crossed the stage quietly.", origin:"Latin", part:"adjective" },
  { word:"imagine", level:"Foundation", definition:"To form a picture or idea in the mind.", sentence:"Imagine discovering a city beneath the sea.", origin:"Latin", part:"verb" },
  { word:"peculiar", level:"Foundation", definition:"Strange, unusual, or distinctive.", sentence:"A peculiar humming sound came from the cupboard.", origin:"Latin", part:"adjective" },
  { word:"treasure", level:"Foundation", definition:"Something greatly valued or a collection of valuable objects.", sentence:"The explorers searched for the hidden treasure.", origin:"Old French", part:"noun" },
  { word:"language", level:"Foundation", definition:"A system of words used for communication.", sentence:"Learning another language can reveal new ideas.", origin:"Old French", part:"noun" },
  { word:"knowledge", level:"Foundation", definition:"Information and understanding gained through learning.", sentence:"Reading widely increased her knowledge of astronomy.", origin:"Old English", part:"noun" },
  { word:"beautiful", level:"Foundation", definition:"Pleasing to the senses or the mind.", sentence:"A beautiful rainbow appeared after the storm.", origin:"French", part:"adjective" },
  { word:"enormous", level:"Foundation", definition:"Extremely large in size or amount.", sentence:"An enormous whale surfaced beside the boat.", origin:"Latin", part:"adjective" },
  { word:"adventure", level:"Foundation", definition:"An unusual and exciting experience.", sentence:"Their forest expedition became an unforgettable adventure.", origin:"Old French", part:"noun" },
  { word:"mischievous", level:"Foundation", definition:"Playfully causing minor trouble.", sentence:"The mischievous puppy hid one of my shoes.", origin:"Old French", part:"adjective" },
  { word:"extraordinary", level:"Foundation", definition:"Very unusual, remarkable, or exceptional.", sentence:"The young musician displayed extraordinary talent.", origin:"Latin", part:"adjective" },
  { word:"necessary", level:"Builder", definition:"Needed or required for a particular purpose.", sentence:"Careful preparation is necessary for the expedition.", origin:"Latin", part:"adjective" },
  { word:"separate", level:"Builder", definition:"To move or keep things apart.", sentence:"Separate the coloured beads into different containers.", origin:"Latin", part:"verb" },
  { word:"privilege", level:"Builder", definition:"A special right, advantage, or opportunity.", sentence:"It was a privilege to represent the school.", origin:"Latin", part:"noun" },
  { word:"conscience", level:"Builder", definition:"An inner sense of what is right and wrong.", sentence:"Her conscience encouraged her to tell the truth.", origin:"Latin", part:"noun" },
  { word:"parliament", level:"Builder", definition:"The lawmaking body of a country.", sentence:"The proposal was debated in parliament.", origin:"Old French", part:"noun" },
  { word:"silhouette", level:"Builder", definition:"The dark outline of a person or object.", sentence:"We saw the bird's silhouette against the sunset.", origin:"French", part:"noun" },
  { word:"camouflage", level:"Builder", definition:"A disguise that helps something blend with its surroundings.", sentence:"The insect's camouflage made it difficult to notice.", origin:"French", part:"noun" },
  { word:"bureaucracy", level:"Builder", definition:"A system administered through departments and official procedures.", sentence:"The application moved slowly through the bureaucracy.", origin:"French", part:"noun" },
  { word:"acquaintance", level:"Builder", definition:"A person one knows but not closely.", sentence:"She greeted an old acquaintance at the exhibition.", origin:"Old French", part:"noun" },
  { word:"perseverance", level:"Builder", definition:"Continued effort despite difficulty or delay.", sentence:"His perseverance helped him master the difficult piece.", origin:"Latin", part:"noun" },
  { word:"pronunciation", level:"Builder", definition:"The way in which a word is spoken.", sentence:"The teacher demonstrated the correct pronunciation.", origin:"Latin", part:"noun" },
  { word:"exaggerate", level:"Builder", definition:"To represent something as greater than it really is.", sentence:"Do not exaggerate the size of the tiny spider.", origin:"Latin", part:"verb" },
  { word:"convenience", level:"Builder", definition:"The quality of being useful, easy, or suitable.", sentence:"The library extended its hours for everyone's convenience.", origin:"Latin", part:"noun" },
  { word:"environment", level:"Builder", definition:"The surroundings and conditions in which life exists.", sentence:"Recycling helps protect the natural environment.", origin:"French", part:"noun" },
  { word:"correspondence", level:"Builder", definition:"Communication by exchanging letters or messages.", sentence:"Their correspondence continued throughout the year.", origin:"Latin", part:"noun" },
  { word:"mediterranean", level:"Builder", definition:"Relating to the Mediterranean Sea or surrounding region.", sentence:"They studied the climate of the Mediterranean region.", origin:"Latin", part:"adjective" },
  { word:"entrepreneur", level:"Builder", definition:"A person who establishes and manages a business.", sentence:"The young entrepreneur created a recycling company.", origin:"French", part:"noun" },
  { word:"manoeuvre", level:"Builder", definition:"A skilful or carefully planned movement.", sentence:"The pilot completed a difficult manoeuvre.", origin:"French", part:"noun" },
  { word:"irresistible", level:"Builder", definition:"Too attractive or powerful to be resisted.", sentence:"The aroma of fresh bread was irresistible.", origin:"Latin", part:"adjective" },
  { word:"conscientious", level:"Builder", definition:"Careful and guided by a desire to do what is right.", sentence:"The conscientious researcher checked every result.", origin:"Latin", part:"adjective" },
  { word:"idiosyncrasy", level:"Championship", definition:"A distinctive habit or characteristic of an individual.", sentence:"His habit of arranging pencils by length was an idiosyncrasy.", origin:"Greek", part:"noun" },
  { word:"juxtaposition", level:"Championship", definition:"The placement of contrasting things beside each other.", sentence:"The painting's juxtaposition of darkness and light was striking.", origin:"Latin", part:"noun" },
  { word:"quintessential", level:"Championship", definition:"Representing the most perfect or typical example.", sentence:"The village is a quintessential example of rural architecture.", origin:"Latin", part:"adjective" },
  { word:"onomatopoeia", level:"Championship", definition:"The formation of a word that imitates a sound.", sentence:"Buzz is a familiar example of onomatopoeia.", origin:"Greek", part:"noun" },
  { word:"chiaroscuro", level:"Championship", definition:"The artistic treatment of strong contrasts between light and shade.", sentence:"The portrait uses chiaroscuro to create dramatic depth.", origin:"Italian", part:"noun" },
  { word:"sesquipedalian", level:"Championship", definition:"Characterised by the use of long words.", sentence:"The speaker's sesquipedalian style puzzled the audience.", origin:"Latin", part:"adjective" },
  { word:"phantasmagoria", level:"Championship", definition:"A rapidly changing sequence of strange or dreamlike images.", sentence:"The performance became a phantasmagoria of colour and shadow.", origin:"Greek", part:"noun" },
  { word:"ecclesiastical", level:"Championship", definition:"Relating to the Christian Church or its clergy.", sentence:"The archive preserves rare ecclesiastical documents.", origin:"Greek", part:"adjective" },
  { word:"magnanimous", level:"Championship", definition:"Generous and forgiving, especially toward a rival.", sentence:"The champion was magnanimous after her victory.", origin:"Latin", part:"adjective" },
  { word:"acquiescence", level:"Championship", definition:"Reluctant acceptance without protest.", sentence:"His silence was interpreted as acquiescence.", origin:"Latin", part:"noun" },
  { word:"connoisseur", level:"Championship", definition:"An expert judge in matters of taste or quality.", sentence:"The connoisseur identified the rare painting immediately.", origin:"French", part:"noun" },
  { word:"kaleidoscopic", level:"Championship", definition:"Displaying complex and continually changing patterns or colours.", sentence:"The festival created a kaleidoscopic display of costumes.", origin:"Greek", part:"adjective" },
  { word:"indefatigable", level:"Championship", definition:"Continuing tirelessly despite prolonged effort.", sentence:"The indefatigable scientist repeated the experiment.", origin:"Latin", part:"adjective" },
  { word:"effervescence", level:"Championship", definition:"A lively, enthusiastic quality or the bubbling of a liquid.", sentence:"Her natural effervescence energised the entire team.", origin:"Latin", part:"noun" },
  { word:"surreptitious", level:"Championship", definition:"Kept secret because it would not be approved.", sentence:"He took a surreptitious glance at the hidden map.", origin:"Latin", part:"adjective" },
  { word:"perspicacious", level:"Championship", definition:"Having a keen ability to understand and notice things.", sentence:"The perspicacious detective recognised the subtle clue.", origin:"Latin", part:"adjective" },
  { word:"incontrovertible", level:"Championship", definition:"Impossible to deny or dispute.", sentence:"The recording provided incontrovertible evidence.", origin:"Latin", part:"adjective" },
  { word:"circumlocution", level:"Championship", definition:"The use of many words where fewer would be clearer.", sentence:"His lengthy circumlocution avoided a direct answer.", origin:"Latin", part:"noun" },
  { word:"lachrymose", level:"Championship", definition:"Tearful or inclined to sadness.", sentence:"The film concluded with a lachrymose farewell.", origin:"Latin", part:"adjective" },
  { word:"prestidigitation", level:"Championship", definition:"Magic performed with skilful movements of the hands.", sentence:"The magician's prestidigitation astonished the audience.", origin:"French", part:"noun" },
];

function audioScripts(entry) {
  return {
    pronunciation: entry.word,
    "pronunciation-slow": entry.word,
    spelling: entry.word.split("").join(". "),
    definition: `Definition. ${entry.definition}`,
    sentence: `Example sentence. ${entry.sentence}`,
    origin: `Origin. ${entry.origin}.`,
    "part-of-speech": `Part of speech. ${entry.part}.`,
  };
}

async function synthesize(text, speed, options = {}) {
  const response = await fetch(
    `https://api.elevenlabs.io/v1/text-to-speech/${ELEVENLABS_VOICE_ID.value()}`,
    {
      method: "POST",
      headers: {
        "xi-api-key": ELEVENLABS_API_KEY.value(),
        "Content-Type": "application/json",
        Accept: "audio/mpeg",
      },
      body: JSON.stringify({
        text,
        model_id: options.model || AUDIO_MODEL,
        ...(options.dictionaryLocators?.length
          ? { pronunciation_dictionary_locators: options.dictionaryLocators }
          : {}),
        voice_settings: {
          stability: options.stability ?? 0.68,
          similarity_boost: options.similarityBoost ?? 0.78,
          style: options.style ?? 0.12,
          use_speaker_boost: true,
          speed,
        },
      }),
    },
  );
  if (!response.ok) {
    throw new Error(`ElevenLabs returned ${response.status}: ${await response.text()}`);
  }
  return Buffer.from(await response.arrayBuffer());
}

async function createAlphabetDictionary() {
  const rules = Object.entries(ALPHABET_PHONEMES).map(([letter, phoneme]) => ({
    string_to_replace: letter === "z-zed" ? "Zed" : letter.toUpperCase(),
    type: "phoneme",
    alphabet: "ipa",
    phoneme,
  }));
  const response = await fetch(
    "https://api.elevenlabs.io/v1/pronunciation-dictionaries/add-from-rules",
    {
      method: "POST",
      headers: {
        "xi-api-key": ELEVENLABS_API_KEY.value(),
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        name: `Alliam alphabet ${Date.now()}`,
        description: "Fixed neutral-English letter names for spelling instruction.",
        rules,
      }),
    },
  );
  if (!response.ok) {
    throw new Error(`ElevenLabs dictionary returned ${response.status}: ${await response.text()}`);
  }
  const dictionary = await response.json();
  return [{
    pronunciation_dictionary_id: dictionary.id,
    version_id: dictionary.version_id,
  }];
}

async function createWordPronunciationDictionary(pronunciations) {
  const rules = Object.entries(pronunciations).flatMap(([word, phoneme]) => [
    { string_to_replace: word, type: "phoneme", alphabet: "ipa", phoneme },
    { string_to_replace: word[0].toUpperCase() + word.slice(1), type: "phoneme", alphabet: "ipa", phoneme },
  ]);
  const response = await fetch(
    "https://api.elevenlabs.io/v1/pronunciation-dictionaries/add-from-rules",
    {
      method: "POST",
      headers: {
        "xi-api-key": ELEVENLABS_API_KEY.value(),
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        name: `Alliam word corrections ${Date.now()}`,
        description: "Approved neutral-English pronunciations for Alliam spelling words.",
        rules,
      }),
    },
  );
  if (!response.ok) {
    throw new Error(`ElevenLabs dictionary returned ${response.status}: ${await response.text()}`);
  }
  const dictionary = await response.json();
  return [{
    pronunciation_dictionary_id: dictionary.id,
    version_id: dictionary.version_id,
  }];
}

exports.buildAudioLibrary = onCall(
  {
    region: AUDIO_REGION,
    secrets: [ELEVENLABS_API_KEY, ELEVENLABS_VOICE_ID],
    timeoutSeconds: 1800,
    memory: "1GiB",
  },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
    const isAudioAdmin = request.auth.token.admin === true ||
      request.auth.token.email === "rimotli.tech@gmail.com";
    if (!isAudioAdmin) {
      throw new HttpsError("permission-denied", "An Alliam audio administrator is required.");
    }

    try {
    const requested = Array.isArray(request.data?.wordIds) ? request.data.wordIds : [];
    const selected = requested.length
      ? WORDS.filter((entry) => requested.includes(entry.word))
      : WORDS;
    if (!selected.length) throw new HttpsError("invalid-argument", "No valid words selected.");

    const db = getFirestore();
    const bucket = getStorage().bucket();
    const versionRef = db.doc(`audioVersions/${AUDIO_VERSION}`);
    await versionRef.set({
      voiceVersion: AUDIO_VERSION,
      voiceId: ELEVENLABS_VOICE_ID.value(),
      model: AUDIO_MODEL,
      status: "generating",
      wordCount: selected.length,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    let assetCount = 0;
    for (const entry of selected) {
      const assets = {};
      for (const [kind, text] of Object.entries(audioScripts(entry))) {
        const path = `audio/${AUDIO_VERSION}/${entry.word}/${kind}.mp3`;
        const audio = await synthesize(text, kind === "pronunciation-slow" ? 0.7 : 1);
        await bucket.file(path).save(audio, {
          resumable: false,
          contentType: "audio/mpeg",
          metadata: {
            cacheControl: "public,max-age=31536000,immutable",
            metadata: { wordId: entry.word, kind, voiceVersion: AUDIO_VERSION },
          },
        });
        assets[kind] = { storagePath: path, contentType: "audio/mpeg" };
        assetCount += 1;
      }
      await db.doc(`words/${entry.word}`).set({
        ...entry,
        audio: assets,
        audioVersion: AUDIO_VERSION,
        audioStatus: "generated",
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    }

    await versionRef.set({
      status: "generated",
      assetCount,
      completedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    return { versionId: AUDIO_VERSION, wordCount: selected.length, assetCount };
    } catch (error) {
      console.error("Audio library generation failed", error);
      throw new HttpsError(
        "internal",
        String(error?.message || "Audio generation failed.").slice(0, 500),
      );
    }
  },
);

exports.regenerateTestPronunciations = onCall(
  {
    region: AUDIO_REGION,
    secrets: [ELEVENLABS_API_KEY, ELEVENLABS_VOICE_ID],
    timeoutSeconds: 300,
    memory: "512MiB",
  },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
    const isAudioAdmin = request.auth.token.admin === true ||
      request.auth.token.email === "rimotli.tech@gmail.com";
    if (!isAudioAdmin) {
      throw new HttpsError("permission-denied", "An Alliam audio administrator is required.");
    }

    const words = [
      "rhythm",
      "extraordinary",
      "conscience",
      "manoeuvre",
      "connoisseur",
      "indefatigable",
      "lachrymose",
    ];
    const version = `alliam-one-v7-slow-natural-${Date.now()}`;
    const bucket = getStorage().bucket();
    const results = {};

    for (const word of words) {
      const path = `audio/${version}/${word}/pronunciation.mp3`;
      const audio = await synthesize(word, 0.70, {
        model: "eleven_flash_v2",
        stability: 1,
      });
      await bucket.file(path).save(audio, {
        resumable: false,
        contentType: "audio/mpeg",
        metadata: {
          cacheControl: "public,max-age=31536000,immutable",
          metadata: { wordId: word, kind: "pronunciation", voiceVersion: version },
        },
      });
      const asset = { storagePath: path, contentType: "audio/mpeg" };
      await getFirestore().doc(`words/${word}`).set({
        audio: { pronunciation: asset },
        pronunciationModel: "eleven_flash_v2",
        pronunciationPhoneme: FieldValue.delete(),
        pronunciationMode: "natural",
        pronunciationSpeed: 0.70,
        pronunciationStability: 1,
        pronunciationVersion: version,
        pronunciationUpdatedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      results[word] = asset;
    }

    return { versionId: version, wordCount: words.length, assetCount: words.length, words: Object.keys(results) };
  },
);

exports.regeneratePrimaryPronunciations = onCall(
  {
    region: AUDIO_REGION,
    secrets: [ELEVENLABS_API_KEY, ELEVENLABS_VOICE_ID],
    timeoutSeconds: 1800,
    memory: "1GiB",
  },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
    const isAudioAdmin = request.auth.token.admin === true ||
      request.auth.token.email === "rimotli.tech@gmail.com";
    if (!isAudioAdmin) {
      throw new HttpsError("permission-denied", "An Alliam audio administrator is required.");
    }

    const version = "alliam-one-v5-natural-voice-8dzk";
    const bucket = getStorage().bucket();
    const db = getFirestore();
    let assetCount = 0;

    for (const entry of WORDS) {
      const word = entry.word;
      const path = `audio/${version}/${word}/pronunciation.mp3`;
      const audio = await synthesize(`${word[0].toUpperCase()}${word.slice(1)}.`, 0.93, {
        model: "eleven_flash_v2",
        stability: 1,
      });
      await bucket.file(path).save(audio, {
        resumable: false,
        contentType: "audio/mpeg",
        metadata: {
          cacheControl: "public,max-age=31536000,immutable",
          metadata: { wordId: word, kind: "pronunciation", voiceVersion: version },
        },
      });
      const asset = { storagePath: path, contentType: "audio/mpeg" };
      await db.doc(`words/${word}`).update({
        "audio.pronunciation": asset,
        pronunciationModel: "eleven_flash_v2",
        pronunciationMode: "natural",
        pronunciationSpeed: 0.93,
        pronunciationStability: 1,
        pronunciationPhoneme: FieldValue.delete(),
        pronunciationVersion: version,
        pronunciationUpdatedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      assetCount += 1;
    }

    await db.doc(`audioVersions/${version}`).set({
      status: "generated",
      kind: "pronunciation-only",
      wordCount: WORDS.length,
      assetCount,
      model: "eleven_flash_v2",
      speed: 0.93,
      stability: 1,
      pronunciationMode: "natural",
      completedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    return { versionId: version, wordCount: WORDS.length, assetCount };
  },
);

exports.approveCoreWordLibrary = onCall(
  {
    region: AUDIO_REGION,
    timeoutSeconds: 1800,
    memory: "1GiB",
  },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
    const isAudioAdmin = request.auth.token.admin === true ||
      request.auth.token.email === "rimotli.tech@gmail.com";
    if (!isAudioAdmin) {
      throw new HttpsError("permission-denied", "An Alliam content administrator is required.");
    }

    const approvalCollection = "core-60-v1";
    const db = getFirestore();
    const bucket = getStorage().bucket();
    let approvedAssetCount = 0;
    const missingAssets = [];

    for (const entry of WORDS) {
      const wordRef = db.doc(`words/${entry.word}`);
      const snapshot = await wordRef.get();
      if (!snapshot.exists) {
        throw new HttpsError("failed-precondition", `Approved word is missing: ${entry.word}`);
      }

      const rawAudio = snapshot.data()?.audio || {};
      const approvedAudio = {};
      for (const [kind, rawAsset] of Object.entries(rawAudio)) {
        const asset = typeof rawAsset === "string"
          ? { storagePath: rawAsset }
          : { ...(rawAsset || {}) };
        if (!asset.storagePath) continue;

        approvedAudio[kind] = {
          ...asset,
          approved: true,
          approvalCollection,
        };

        const file = bucket.file(asset.storagePath);
        try {
          const [metadata] = await file.getMetadata();
          await file.setMetadata({
            metadata: {
              ...(metadata.metadata || {}),
              approved: "true",
              approvalCollection,
              approvedWord: entry.word,
              approvedAudioKind: kind,
            },
          });
          approvedAssetCount += 1;
        } catch (error) {
          if (Number(error?.code) === 404) {
            missingAssets.push(asset.storagePath);
          } else {
            throw error;
          }
        }
      }

      if (!approvedAudio.pronunciation?.storagePath) {
        throw new HttpsError(
          "failed-precondition",
          `Approved word has no primary pronunciation: ${entry.word}`,
        );
      }

      await wordRef.set({
        approved: true,
        status: "published",
        approvalCollection,
        approvedAt: FieldValue.serverTimestamp(),
        approvedAudio,
        audio: approvedAudio,
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
    }

    await db.doc(`wordCollections/${approvalCollection}`).set({
      id: approvalCollection,
      approved: true,
      status: "published",
      wordCount: WORDS.length,
      approvedAssetCount,
      missingAssets,
      wordIds: WORDS.map((entry) => entry.word),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    return {
      approvalCollection,
      wordCount: WORDS.length,
      approvedAssetCount,
      missingAssetCount: missingAssets.length,
      missingAssets,
    };
  },
);

exports.generateApprovedNext200Pronunciations = onCall(
  {
    region: AUDIO_REGION,
    secrets: [ELEVENLABS_API_KEY, ELEVENLABS_VOICE_ID],
    timeoutSeconds: 1800,
    memory: "1GiB",
  },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
    const isAudioAdmin = request.auth.token.admin === true ||
      request.auth.token.email === "rimotli.tech@gmail.com";
    if (!isAudioAdmin) {
      throw new HttpsError("permission-denied", "An Alliam audio administrator is required.");
    }

    const approvalCollection = "grade-1-2-200-v1";
    const version = `${approvalCollection}-${Date.now()}`;
    const db = getFirestore();
    const bucket = getStorage().bucket();
    const manifestRef = db.doc(`wordCollections/${approvalCollection}`);
    let generatedCount = 0;

    await manifestRef.set({
      id: approvalCollection,
      approved: false,
      status: "generating",
      wordCount: NEXT_200_WORDS.length,
      generatedCount: 0,
      voiceId: ELEVENLABS_VOICE_ID.value(),
      model: "eleven_flash_v2",
      speed: 0.70,
      stability: 1,
      pronunciationMode: "natural",
      version,
      wordIds: NEXT_200_WORDS.map((entry) => entry.word),
      startedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    try {
      for (const entry of NEXT_200_WORDS) {
        const path = `audio/${version}/${entry.word}/pronunciation.mp3`;
        const audio = await synthesize(entry.word, 0.70, {
          model: "eleven_flash_v2",
          stability: 1,
        });
        await bucket.file(path).save(audio, {
          resumable: false,
          contentType: "audio/mpeg",
          metadata: {
            cacheControl: "public,max-age=31536000,immutable",
            metadata: {
              wordId: entry.word,
              kind: "pronunciation",
              voiceVersion: version,
              approved: "true",
              approvalCollection,
              stage: String(entry.stage),
              grade: entry.grade,
            },
          },
        });

        const asset = {
          storagePath: path,
          contentType: "audio/mpeg",
          approved: true,
          approvalCollection,
        };
        await db.doc(`words/${entry.word}`).set({
          word: entry.word,
          level: entry.level,
          grade: entry.grade,
          stage: entry.stage,
          approved: true,
          status: "published",
          approvalCollection,
          audio: { pronunciation: asset },
          approvedAudio: { pronunciation: asset },
          pronunciationModel: "eleven_flash_v2",
          pronunciationMode: "natural",
          pronunciationSpeed: 0.70,
          pronunciationStability: 1,
          pronunciationPhoneme: FieldValue.delete(),
          pronunciationVersion: version,
          pronunciationUpdatedAt: FieldValue.serverTimestamp(),
          approvedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        }, { merge: true });

        generatedCount += 1;
        if (generatedCount % 10 === 0) {
          await manifestRef.set({
            generatedCount,
            updatedAt: FieldValue.serverTimestamp(),
          }, { merge: true });
        }
      }

      const retryWord = "rhythm";
      const retryPath = `audio/${version}/${retryWord}/pronunciation.mp3`;
      const retryAudio = await synthesize(retryWord, 0.70, {
        model: "eleven_flash_v2",
        stability: 1,
      });
      await bucket.file(retryPath).save(retryAudio, {
        resumable: false,
        contentType: "audio/mpeg",
        metadata: {
          cacheControl: "public,max-age=31536000,immutable",
          metadata: {
            wordId: retryWord,
            kind: "pronunciation",
            voiceVersion: version,
            approved: "true",
            approvalCollection: "core-60-v1",
            reviewRetry: "single-syllable-natural-intonation",
          },
        },
      });
      const retryAsset = {
        storagePath: retryPath,
        contentType: "audio/mpeg",
        approved: true,
        approvalCollection: "core-60-v1",
      };
      await db.doc(`words/${retryWord}`).set({
        audio: { pronunciation: retryAsset },
        approvedAudio: { pronunciation: retryAsset },
        pronunciationModel: "eleven_flash_v2",
        pronunciationMode: "natural",
        pronunciationSpeed: 0.70,
        pronunciationStability: 1,
        pronunciationPhoneme: FieldValue.delete(),
        pronunciationVersion: version,
        pronunciationReviewRetry: "single-syllable-natural-intonation",
        pronunciationUpdatedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });

      await manifestRef.set({
        approved: true,
        status: "published",
        generatedCount,
        assetCount: generatedCount,
        queuedRetryCount: 1,
        queuedRetryWords: [retryWord],
        totalGeneratedAudioCount: generatedCount + 1,
        completedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });

      return {
        approvalCollection,
        version,
        wordCount: NEXT_200_WORDS.length,
        assetCount: generatedCount,
        queuedRetryCount: 1,
        queuedRetryWords: [retryWord],
        totalGeneratedAudioCount: generatedCount + 1,
      };
    } catch (error) {
      await manifestRef.set({
        approved: false,
        status: "failed",
        generatedCount,
        error: String(error?.message || error).slice(0, 500),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      console.error("Approved 200-word generation failed", error);
      throw new HttpsError(
        "internal",
        String(error?.message || "Approved word generation failed.").slice(0, 500),
      );
    }
  },
);

exports.buildAlphabetLibrary = onCall(
  {
    region: AUDIO_REGION,
    secrets: [ELEVENLABS_API_KEY, ELEVENLABS_VOICE_ID],
    timeoutSeconds: 900,
    memory: "1GiB",
  },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
    const isAudioAdmin = request.auth.token.admin === true ||
      request.auth.token.email === "rimotli.tech@gmail.com";
    if (!isAudioAdmin) {
      throw new HttpsError("permission-denied", "An Alliam audio administrator is required.");
    }
    try {
      const bucket = getStorage().bucket();
      const dictionaryLocators = await createAlphabetDictionary();
      const alphabet = {};
      for (const letter of Object.keys(ALPHABET_PHONEMES)) {
        const text = letter === "z-zed" ? "Zed" : letter.toUpperCase();
        const path = `audio/${ALPHABET_VERSION}/alphabet/${letter}.mp3`;
        const audio = await synthesize(text, 0.9, {
          model: "eleven_flash_v2",
          dictionaryLocators,
        });
        await bucket.file(path).save(audio, {
          resumable: false,
          contentType: "audio/mpeg",
          metadata: {
            cacheControl: "public,max-age=31536000,immutable",
            metadata: { letter, kind: "alphabet", voiceVersion: ALPHABET_VERSION },
          },
        });
        alphabet[letter] = { storagePath: path, contentType: "audio/mpeg" };
      }
      await getFirestore().doc(`audioVersions/${ALPHABET_VERSION}`).set({
        alphabet,
        alphabetStatus: "generated",
        alphabetAssetCount: Object.keys(alphabet).length,
        model: "eleven_flash_v2",
        pronunciationMode: "ipa-dictionary",
        alphabetUpdatedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      }, { merge: true });
      return {
        versionId: ALPHABET_VERSION,
        assetCount: Object.keys(alphabet).length,
        letterCount: 26,
      };
    } catch (error) {
      console.error("Alphabet generation failed", error);
      throw new HttpsError(
        "internal",
        String(error?.message || "Alphabet generation failed.").slice(0, 500),
      );
    }
  },
);

exports.installManualAlphabet = onCall(
  {
    region: AUDIO_REGION,
    timeoutSeconds: 300,
    memory: "512MiB",
  },
  async (request) => {
    if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
    const isAudioAdmin = request.auth.token.admin === true ||
      request.auth.token.email === "rimotli.tech@gmail.com";
    if (!isAudioAdmin) {
      throw new HttpsError("permission-denied", "An Alliam audio administrator is required.");
    }

    const files = request.data?.files;
    const expected = "abcdefghijklmnopqrstuvwxyz".split("");
    if (!files || expected.some((letter) => typeof files[letter] !== "string")) {
      throw new HttpsError("invalid-argument", "Provide one MP3 file for every letter from A to Z.");
    }

    const bucket = getStorage().bucket();
    const alphabet = {};
    for (const letter of expected) {
      const audio = Buffer.from(files[letter], "base64");
      if (audio.length < 500 || audio.length > 2 * 1024 * 1024) {
        throw new HttpsError("invalid-argument", `${letter.toUpperCase()}.mp3 has an invalid file size.`);
      }
      const path = `audio/alliam-alphabet-manual-v1/alphabet/${letter}.mp3`;
      await bucket.file(path).save(audio, {
        resumable: false,
        contentType: "audio/mpeg",
        metadata: {
          cacheControl: "public,max-age=31536000,immutable",
          metadata: { letter, kind: "alphabet", voiceVersion: "alliam-alphabet-manual-v1" },
        },
      });
      alphabet[letter] = { storagePath: path, contentType: "audio/mpeg" };
    }

    await getFirestore().doc(`audioVersions/${ALPHABET_VERSION}`).set({
      alphabet,
      alphabetStatus: "generated",
      alphabetAssetCount: 26,
      model: "human-recording",
      pronunciationMode: "recorded-letter-names",
      sourceVersion: "alliam-alphabet-manual-v1",
      alphabetUpdatedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });

    return { versionId: ALPHABET_VERSION, sourceVersion: "alliam-alphabet-manual-v1", assetCount: 26 };
  },
);

const SPEECH_REGION = "southafricanorth";
const TOKEN_ENDPOINT =
  `https://${SPEECH_REGION}.api.cognitive.microsoft.com/sts/v1.0/issueToken`;

exports.issueSpeechToken = onRequest(
  {
    region: "europe-west1",
    secrets: [AZURE_SPEECH_KEY],
    cors: [
      "https://spelliam-ad3fd.web.app",
      "https://spelliam-ad3fd.firebaseapp.com",
      /^http:\/\/localhost(:\d+)?$/,
      /^http:\/\/127\.0\.0\.1(:\d+)?$/,
    ],
    timeoutSeconds: 30,
    memory: "256MiB",
  },
  async (request, response) => {
    if (request.method !== "POST") {
      response.set("Allow", "POST").status(405).json({ error: "method-not-allowed" });
      return;
    }

    const authorization = request.get("Authorization") || "";
    const match = authorization.match(/^Bearer (.+)$/);
    if (!match) {
      response.status(401).json({ error: "authentication-required" });
      return;
    }

    try {
      await getAuth().verifyIdToken(match[1]);

      const azureResponse = await fetch(TOKEN_ENDPOINT, {
        method: "POST",
        headers: {
          "Ocp-Apim-Subscription-Key": AZURE_SPEECH_KEY.value(),
          "Content-Length": "0",
        },
      });

      if (!azureResponse.ok) {
        console.error("Azure Speech token request failed", {
          status: azureResponse.status,
          body: await azureResponse.text(),
        });
        response.status(502).json({ error: "speech-token-unavailable" });
        return;
      }

      response.set("Cache-Control", "private, no-store").status(200).json({
        token: await azureResponse.text(),
        region: SPEECH_REGION,
        expiresInSeconds: 540,
      });
    } catch (error) {
      console.error("Speech token function failed", error);
      response.status(401).json({ error: "invalid-authentication" });
    }
  }
);

const db = getFirestore();
const PUBLIC_PLAYER_FIELDS = ["displayName", "nickname", "grade", "country", "school", "avatar"];

function requireUser(request) {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
  return request.auth.uid;
}

function cleanText(value, max = 80) {
  return String(value || "").trim().replace(/\s+/g, " ").slice(0, max);
}

function publicProfile(data = {}) {
  const profile = {};
  for (const field of PUBLIC_PLAYER_FIELDS) profile[field] = cleanText(data[field], 80);
  return profile;
}

function friendCode(uid) {
  return `AL-${uid.replace(/[^a-z0-9]/gi, "").slice(0, 7).toUpperCase()}`;
}

function randomCode() {
  return Math.random().toString(36).slice(2, 8).toUpperCase();
}

function wordIdsForMatch() {
  const offset = Math.floor(Math.random() * WORDS.length);
  return Array.from({ length: 5 }, (_, index) => WORDS[(offset + index) % WORDS.length].word);
}

async function playerSnapshot(uid) {
  const snapshot = await db.doc(`players/${uid}`).get();
  if (!snapshot.exists) throw new HttpsError("failed-precondition", "Complete your player profile first.");
  return snapshot;
}

async function createMatch(playerOne, playerTwo, mode = "Casual 1v1", extra = {}) {
  const [one, two] = await Promise.all([playerSnapshot(playerOne), playerSnapshot(playerTwo)]);
  const ref = db.collection("matches").doc();
  const words = wordIdsForMatch();
  await ref.set({
    players: [playerOne, playerTwo],
    playerProfiles: {
      [playerOne]: publicProfile(one.data()),
      [playerTwo]: publicProfile(two.data()),
    },
    mode: cleanText(mode, 32),
    status: "active",
    totalRounds: words.length,
    currentRound: 0,
    wordIds: words,
    scores: { [playerOne]: 0, [playerTwo]: 0 },
    submissions: {},
    winnerUid: null,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    ...extra,
  });
  const batch = db.batch();
  for (const uid of [playerOne, playerTwo]) {
    batch.set(db.doc(`matchAssignments/${uid}`), {
      matchId: ref.id,
      status: "active",
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  return ref.id;
}

exports.bootstrapPlayer = onCall({ region: AUDIO_REGION }, async (request) => {
  const uid = requireUser(request);
  const ref = db.doc(`players/${uid}`);
  const existing = await ref.get();
  const profile = publicProfile(request.data?.profile);
  const code = existing.data()?.friendCode || friendCode(uid);
  const payload = {
    ...profile,
    friendCode: code,
    rating: existing.data()?.rating || 1200,
    matchCount: existing.data()?.matchCount || 0,
    wins: existing.data()?.wins || 0,
    updatedAt: FieldValue.serverTimestamp(),
  };
  if (!existing.exists) payload.createdAt = FieldValue.serverTimestamp();
  await ref.set(payload, { merge: true });
  await db.doc(`friendCodes/${code}`).set({ uid, updatedAt: FieldValue.serverTimestamp() });
  return { uid, friendCode: code };
});

exports.sendFriendRequest = onCall({ region: AUDIO_REGION }, async (request) => {
  const senderUid = requireUser(request);
  const code = cleanText(request.data?.friendCode, 20).toUpperCase();
  const codeSnap = await db.doc(`friendCodes/${code}`).get();
  if (!codeSnap.exists) throw new HttpsError("not-found", "No player has that friend code.");
  const recipientUid = codeSnap.data().uid;
  if (recipientUid === senderUid) throw new HttpsError("invalid-argument", "That is your own friend code.");
  const id = [senderUid, recipientUid].sort().join("_");
  const [sender, recipient] = await Promise.all([playerSnapshot(senderUid), playerSnapshot(recipientUid)]);
  await db.doc(`friendRequests/${id}`).set({
    senderUid,
    recipientUid,
    senderProfile: publicProfile(sender.data()),
    recipientProfile: publicProfile(recipient.data()),
    status: "pending",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
  return { requestId: id };
});

exports.respondFriendRequest = onCall({ region: AUDIO_REGION }, async (request) => {
  const uid = requireUser(request);
  const requestId = cleanText(request.data?.requestId, 160);
  const accept = request.data?.accept === true;
  const ref = db.doc(`friendRequests/${requestId}`);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists || snapshot.data().recipientUid !== uid) {
      throw new HttpsError("permission-denied", "This request is not yours.");
    }
    const data = snapshot.data();
    transaction.update(ref, { status: accept ? "accepted" : "declined", updatedAt: FieldValue.serverTimestamp() });
    if (accept) {
      const friendshipId = [data.senderUid, data.recipientUid].sort().join("_");
      transaction.set(db.doc(`friendships/${friendshipId}`), {
        memberUids: [data.senderUid, data.recipientUid],
        profiles: {
          [data.senderUid]: data.senderProfile,
          [data.recipientUid]: data.recipientProfile,
        },
        createdAt: FieldValue.serverTimestamp(),
      });
    }
  });
  return { accepted: accept };
});

exports.createTeam = onCall({ region: AUDIO_REGION }, async (request) => {
  const uid = requireUser(request);
  const owner = await playerSnapshot(uid);
  const name = cleanText(request.data?.name, 50);
  if (name.length < 3) throw new HttpsError("invalid-argument", "Enter a team name.");
  const ref = db.collection("teams").doc();
  await ref.set({
    name,
    school: cleanText(request.data?.school || owner.data().school, 80),
    ownerUid: uid,
    memberUids: [uid],
    members: { [uid]: { ...publicProfile(owner.data()), role: "captain" } },
    rating: 1200,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return { teamId: ref.id };
});

exports.createEvent = onCall({ region: AUDIO_REGION }, async (request) => {
  const uid = requireUser(request);
  const organizer = await playerSnapshot(uid);
  const title = cleanText(request.data?.title, 80);
  if (!title) throw new HttpsError("invalid-argument", "Enter an event title.");
  const ref = db.collection("events").doc();
  await ref.set({
    title,
    type: cleanText(request.data?.type || "fixture", 24),
    school: cleanText(request.data?.school || organizer.data().school, 80),
    organizerUid: uid,
    participantUids: [uid],
    status: "scheduled",
    startsAt: request.data?.startsAt || null,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return { eventId: ref.id };
});

exports.joinMatchQueue = onCall({ region: AUDIO_REGION }, async (request) => {
  const uid = requireUser(request);
  await playerSnapshot(uid);
  const mode = cleanText(request.data?.mode || "Casual 1v1", 32);
  const waiting = await db.collection("matchQueue").where("status", "==", "waiting").limit(20).get();
  const opponent = waiting.docs.find((doc) => doc.id !== uid && doc.data().mode === mode);
  if (!opponent) {
    await db.doc(`matchQueue/${uid}`).set({
      uid, mode, status: "waiting", createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
    });
    return { status: "waiting" };
  }
  const claimed = await db.runTransaction(async (transaction) => {
    const opponentRef = db.doc(`matchQueue/${opponent.id}`);
    const fresh = await transaction.get(opponentRef);
    if (!fresh.exists || fresh.data().status !== "waiting") return false;
    transaction.delete(opponentRef);
    transaction.delete(db.doc(`matchQueue/${uid}`));
    return true;
  });
  if (!claimed) return { status: "retry" };
  const matchId = await createMatch(opponent.id, uid, mode);
  return { status: "matched", matchId };
});

exports.cancelMatchQueue = onCall({ region: AUDIO_REGION }, async (request) => {
  const uid = requireUser(request);
  await db.doc(`matchQueue/${uid}`).delete();
  return { cancelled: true };
});

exports.forfeitMatch = onCall({ region: AUDIO_REGION }, async (request) => {
  const uid = requireUser(request);
  const matchId = cleanText(request.data?.matchId, 160);
  if (!matchId) throw new HttpsError("invalid-argument", "Match ID is required.");
  const ref = db.doc(`matches/${matchId}`);
  let winnerUid = null;
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists) throw new HttpsError("not-found", "Match not found.");
    const match = snapshot.data();
    if (!match.players.includes(uid)) throw new HttpsError("permission-denied", "This is not your match.");
    if (match.status !== "active") throw new HttpsError("failed-precondition", "This match has already ended.");
    winnerUid = match.players.find((player) => player !== uid);
    transaction.update(ref, {
      status: "completed",
      completionReason: "forfeit",
      forfeitedBy: uid,
      winnerUid,
      completedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
  const batch = db.batch();
  batch.update(db.doc(`players/${uid}`), {
    rating: FieldValue.increment(-16),
    matchCount: FieldValue.increment(1),
    updatedAt: FieldValue.serverTimestamp(),
  });
  batch.update(db.doc(`players/${winnerUid}`), {
    rating: FieldValue.increment(16),
    matchCount: FieldValue.increment(1),
    wins: FieldValue.increment(1),
    updatedAt: FieldValue.serverTimestamp(),
  });
  await batch.commit();
  return { forfeited: true, winnerUid, ratingDelta: -16 };
});

exports.submitMatchRound = onCall({ region: AUDIO_REGION }, async (request) => {
  const uid = requireUser(request);
  const matchId = cleanText(request.data?.matchId, 160);
  const attempt = cleanText(request.data?.attempt, 80).toLowerCase();
  const ref = db.doc(`matches/${matchId}`);
  let completed = false;
  let ratingUpdates = null;
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists) throw new HttpsError("not-found", "Match not found.");
    const match = snapshot.data();
    if (!match.players.includes(uid) || match.status !== "active") {
      throw new HttpsError("failed-precondition", "This match is not active.");
    }
    const round = match.currentRound;
    const key = `${round}_${uid}`;
    if (match.submissions?.[key]) throw new HttpsError("already-exists", "Round already submitted.");
    const expected = match.wordIds[round];
    const correct = attempt === expected;
    const submissions = { ...(match.submissions || {}), [key]: { attempt, correct, submittedAt: Date.now() } };
    const scores = { ...match.scores, [uid]: (match.scores[uid] || 0) + (correct ? 1 : 0) };
    const otherUid = match.players.find((player) => player !== uid);
    const bothDone = Boolean(submissions[`${round}_${otherUid}`]);
    const update = { submissions, scores, updatedAt: FieldValue.serverTimestamp() };
    if (bothDone) {
      if (round + 1 >= match.totalRounds) {
        completed = true;
        update.status = "completed";
        update.completedAt = FieldValue.serverTimestamp();
        update.winnerUid = scores[uid] === scores[otherUid] ? null : (scores[uid] > scores[otherUid] ? uid : otherUid);
        const delta = update.winnerUid ? 16 : 4;
        ratingUpdates = match.players.map((player) => ({
          uid: player,
          delta: update.winnerUid === null ? delta : (player === update.winnerUid ? delta : -delta),
          won: player === update.winnerUid,
        }));
      } else {
        update.currentRound = round + 1;
      }
    }
    transaction.update(ref, update);
  });
  if (ratingUpdates) {
    const batch = db.batch();
    for (const item of ratingUpdates) {
      batch.update(db.doc(`players/${item.uid}`), {
        rating: FieldValue.increment(item.delta),
        matchCount: FieldValue.increment(1),
        wins: FieldValue.increment(item.won ? 1 : 0),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
  return { submitted: true, completed };
});

exports.createInvitation = onCall({ region: AUDIO_REGION }, async (request) => {
  const senderUid = requireUser(request);
  const recipientUid = cleanText(request.data?.recipientUid, 160);
  if (!recipientUid || recipientUid === senderUid) throw new HttpsError("invalid-argument", "Choose another player.");
  const [sender, recipient] = await Promise.all([playerSnapshot(senderUid), playerSnapshot(recipientUid)]);
  const ref = db.collection("invitations").doc();
  await ref.set({
    senderUid, recipientUid,
    senderProfile: publicProfile(sender.data()),
    recipientProfile: publicProfile(recipient.data()),
    mode: cleanText(request.data?.mode || "Private 1v1", 32),
    status: "pending",
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });
  return { invitationId: ref.id };
});

exports.respondInvitation = onCall({ region: AUDIO_REGION }, async (request) => {
  const uid = requireUser(request);
  const invitationId = cleanText(request.data?.invitationId, 160);
  const accept = request.data?.accept === true;
  const ref = db.doc(`invitations/${invitationId}`);
  const snapshot = await ref.get();
  if (!snapshot.exists || snapshot.data().recipientUid !== uid) throw new HttpsError("permission-denied", "This invitation is not yours.");
  const data = snapshot.data();
  if (!accept) {
    await ref.update({ status: "declined", updatedAt: FieldValue.serverTimestamp() });
    return { accepted: false };
  }
  const matchId = await createMatch(data.senderUid, data.recipientUid, data.mode, { invitationId });
  await ref.update({ status: "accepted", matchId, updatedAt: FieldValue.serverTimestamp() });
  return { accepted: true, matchId };
});

exports.createPrivateRoom = onCall({ region: AUDIO_REGION }, async (request) => {
  const uid = requireUser(request);
  await playerSnapshot(uid);
  let code = randomCode();
  while ((await db.doc(`privateRooms/${code}`).get()).exists) code = randomCode();
  await db.doc(`privateRooms/${code}`).set({
    ownerUid: uid, status: "waiting", createdAt: FieldValue.serverTimestamp(), updatedAt: FieldValue.serverTimestamp(),
  });
  return { code };
});

exports.joinPrivateRoom = onCall({ region: AUDIO_REGION }, async (request) => {
  const uid = requireUser(request);
  const code = cleanText(request.data?.code, 12).toUpperCase();
  const ref = db.doc(`privateRooms/${code}`);
  const snapshot = await ref.get();
  if (!snapshot.exists || snapshot.data().status !== "waiting") throw new HttpsError("not-found", "Room is unavailable.");
  if (snapshot.data().ownerUid === uid) throw new HttpsError("invalid-argument", "Share this room code with another player.");
  const matchId = await createMatch(snapshot.data().ownerUid, uid, "Private 1v1", { roomCode: code });
  await ref.update({ status: "matched", matchId, joinedUid: uid, updatedAt: FieldValue.serverTimestamp() });
  return { matchId };
});
