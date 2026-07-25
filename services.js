(function () {
  const config = window.ALLIAM_CONFIG;

  const delay = (ms = 180) => new Promise(resolve => setTimeout(resolve, ms));

  const firebaseConfigIsComplete = () => {
    const value = config.firebase;
    return Boolean(
      value.enabled &&
      window.firebase &&
      value.apiKey && !value.apiKey.startsWith("FIREBASE_") &&
      value.appId && !value.appId.startsWith("FIREBASE_")
    );
  };

  let firebaseApp;
  let auth;
  let db;
  let storage;

  function initializeFirebase() {
    if (!firebaseConfigIsComplete()) return false;
    if (firebaseApp) return true;
    firebaseApp = window.firebase.apps.length
      ? window.firebase.app()
      : window.firebase.initializeApp(config.firebase);
    auth = window.firebase.auth();
    db = window.firebase.firestore();
    storage = window.firebase.storage();
    auth.setPersistence(window.firebase.auth.Auth.Persistence.LOCAL).catch(() => {});
    return true;
  }

  async function ensureFirebaseUser() {
    if (!initializeFirebase()) return null;
    if (auth.currentUser) return auth.currentUser;
    const credential = await auth.signInAnonymously();
    return credential.user;
  }

  async function callFunction(name, data = {}) {
    const user = await ensureFirebaseUser();
    if (!user || user.isAnonymous) throw new Error("Create or sign in to an account to use live features.");
    const response = await fetch(
      `https://europe-west1-spelliam-ad3fd.cloudfunctions.net/${name}`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${await user.getIdToken()}`,
          "Content-Type": "application/json"
        },
        body: JSON.stringify({ data })
      }
    );
    const payload = await response.json();
    if (!response.ok || payload.error) {
      throw new Error(payload.error?.message || `${name} failed.`);
    }
    return payload.result;
  }

  function mappedSubscription(query, callback, mapper = snapshot => ({ id: snapshot.id, ...snapshot.data() })) {
    return query.onSnapshot(
      snapshot => callback(snapshot.docs.map(mapper)),
      error => console.warn("Realtime subscription failed", error)
    );
  }

  const firebase = {
    get configured() { return firebaseConfigIsComplete(); },
    get user() { return auth?.currentUser || null; },
    initialize: initializeFirebase,
    async createAccount(email, password, profile = {}) {
      if (!this.configured) throw new Error("Firebase Authentication is not configured.");
      initializeFirebase();
      const credential = await auth.createUserWithEmailAndPassword(email, password);
      if (profile.displayName) await credential.user.updateProfile({ displayName: profile.displayName });
      await db.doc(`accounts/${credential.user.uid}`).set({
        email: credential.user.email,
        role: profile.role || "student",
        displayName: profile.displayName || "",
        createdAt: window.firebase.firestore.FieldValue.serverTimestamp(),
        updatedAt: window.firebase.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      return credential.user;
    },
    async login(email, password) {
      if (!this.configured) throw new Error("Firebase Authentication is not configured.");
      initializeFirebase();
      const credential = await auth.signInWithEmailAndPassword(email, password);
      return credential.user;
    },
    async loadAccountProfile() {
      if (!this.configured) return null;
      const user = await ensureFirebaseUser();
      const snapshot = await db.doc(`accounts/${user.uid}`).get();
      return snapshot.exists ? snapshot.data() : null;
    },
    async updateAccountProfile(profile = {}) {
      if (!this.configured) return;
      const user = await ensureFirebaseUser();
      await db.doc(`accounts/${user.uid}`).set({
        ...profile,
        email: user.email || "",
        updatedAt: window.firebase.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
    },
    call: callFunction,
    async bootstrapPlayer(profile = {}) {
      return callFunction("bootstrapPlayer", { profile });
    },
    async sendFriendRequest(friendCode) {
      return callFunction("sendFriendRequest", { friendCode });
    },
    async respondFriendRequest(requestId, accept) {
      return callFunction("respondFriendRequest", { requestId, accept });
    },
    async createTeam(name, school) {
      return callFunction("createTeam", { name, school });
    },
    async createEvent(event) {
      return callFunction("createEvent", event);
    },
    async joinMatchQueue(mode) {
      return callFunction("joinMatchQueue", { mode });
    },
    async cancelMatchQueue() {
      return callFunction("cancelMatchQueue");
    },
    async submitMatchRound(matchId, attempt) {
      return callFunction("submitMatchRound", { matchId, attempt });
    },
    async forfeitMatch(matchId) {
      return callFunction("forfeitMatch", { matchId });
    },
    async createInvitation(recipientUid, mode = "Private 1v1") {
      return callFunction("createInvitation", { recipientUid, mode });
    },
    async respondInvitation(invitationId, accept) {
      return callFunction("respondInvitation", { invitationId, accept });
    },
    async createPrivateRoom() {
      return callFunction("createPrivateRoom");
    },
    async joinPrivateRoom(code) {
      return callFunction("joinPrivateRoom", { code });
    },
    subscribeLiveData(handlers = {}) {
      if (!initializeFirebase() || !auth.currentUser) return () => {};
      const uid = auth.currentUser.uid;
      const unsubscribers = [];
      if (handlers.player) unsubscribers.push(db.doc(`players/${uid}`).onSnapshot(s => handlers.player(s.exists ? { id: s.id, ...s.data() } : null)));
      if (handlers.leaderboard) unsubscribers.push(mappedSubscription(db.collection("players").orderBy("rating", "desc").limit(50), handlers.leaderboard));
      if (handlers.friendRequests) unsubscribers.push(mappedSubscription(db.collection("friendRequests").where("recipientUid", "==", uid), handlers.friendRequests));
      if (handlers.friends) unsubscribers.push(mappedSubscription(db.collection("friendships").where("memberUids", "array-contains", uid), handlers.friends));
      if (handlers.teams) unsubscribers.push(mappedSubscription(db.collection("teams").where("memberUids", "array-contains", uid), handlers.teams));
      if (handlers.events) unsubscribers.push(mappedSubscription(db.collection("events").where("participantUids", "array-contains", uid), handlers.events));
      if (handlers.invitations) unsubscribers.push(mappedSubscription(db.collection("invitations").where("recipientUid", "==", uid), handlers.invitations));
      if (handlers.assignment) unsubscribers.push(db.doc(`matchAssignments/${uid}`).onSnapshot(s => handlers.assignment(s.exists ? s.data() : null)));
      return () => unsubscribers.forEach(unsubscribe => unsubscribe());
    },
    subscribeMatch(matchId, callback) {
      if (!initializeFirebase()) return () => {};
      return db.doc(`matches/${matchId}`).onSnapshot(snapshot => callback(snapshot.exists ? { id: snapshot.id, ...snapshot.data() } : null));
    },
    async signInDemo(profile = {}) {
      if (!this.configured) return { uid: `local-${Date.now()}`, isAnonymous: true };
      const user = await ensureFirebaseUser();
      await db.doc(`accounts/${user.uid}`).set({
        role: profile.role || "student",
        demo: true,
        updatedAt: window.firebase.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      return user;
    },
    async signIn(profile) {
      if (!this.configured) {
        await delay();
        return { uid: profile.id || `local-${Date.now()}`, ...profile, source: "local" };
      }
      const user = await ensureFirebaseUser();
      await db.doc(`accounts/${user.uid}`).set({
        role: profile.role || "learner",
        updatedAt: window.firebase.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      return { uid: user.uid, ...profile, source: "firebase" };
    },
    async save(path, value) {
      if (!this.configured) {
        localStorage.setItem(`alliam:${path}`, JSON.stringify(value));
        return { source: "local" };
      }
      const user = await ensureFirebaseUser();
      const documentId = encodeURIComponent(path);
      await db.doc(`accounts/${user.uid}/data/${documentId}`).set({
        value,
        updatedAt: window.firebase.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      return { source: "firebase", uid: user.uid };
    },
    async load(path) {
      if (!this.configured) {
        const value = localStorage.getItem(`alliam:${path}`) || localStorage.getItem(`spelliam:${path}`);
        return value ? JSON.parse(value) : null;
      }
      const user = await ensureFirebaseUser();
      const documentId = encodeURIComponent(path);
      const snapshot = await db.doc(`accounts/${user.uid}/data/${documentId}`).get();
      return snapshot.exists ? snapshot.data().value : null;
    },
    async uploadAudio(storagePath, file, metadata = {}) {
      if (!this.configured) throw new Error("Firebase Storage is not configured.");
      await ensureFirebaseUser();
      const snapshot = await storage.ref(storagePath).put(file, metadata);
      return { path: snapshot.ref.fullPath, url: await snapshot.ref.getDownloadURL() };
    },
    async loadWordAudio(wordIds = []) {
      if (!this.configured || !wordIds.length) return {};
      await ensureFirebaseUser();
      const snapshots = await Promise.all(wordIds.map(id => db.doc(`words/${id}`).get()));
      const result = {};
      for (const snapshot of snapshots) {
        if (!snapshot.exists) continue;
        const assets = snapshot.data().audio || {};
        const resolved = {};
        await Promise.all(Object.entries(assets).map(async ([kind, asset]) => {
          const path = typeof asset === "string" ? asset : asset.storagePath;
          if (path) resolved[kind] = await storage.ref(path).getDownloadURL();
        }));
        result[snapshot.id] = {
          version: snapshot.data().audioVersion || "",
          normal: resolved.pronunciation,
          slow: resolved["pronunciation-slow"],
          spelling: resolved.spelling,
          definition: resolved.definition,
          sentence: resolved.sentence,
          origin: resolved.origin,
          partOfSpeech: resolved["part-of-speech"]
        };
      }
      return result;
    },
    async loadAlphabetAudio(versionId = "alliam-alphabet-v2") {
      if (!this.configured) return {};
      await ensureFirebaseUser();
      const snapshot = await db.doc(`audioVersions/${versionId}`).get();
      if (!snapshot.exists) return {};
      const assets = snapshot.data().alphabet || {};
      const result = {};
      await Promise.all(Object.entries(assets).map(async ([letter, asset]) => {
        const path = typeof asset === "string" ? asset : asset.storagePath;
        if (path) result[letter] = await storage.ref(path).getDownloadURL();
      }));
      return result;
    },
    async buildAudioLibrary(wordIds = []) {
      if (!this.configured) throw new Error("Firebase is not configured.");
      initializeFirebase();
      const user = auth.currentUser;
      if (!user) throw new Error("Sign in with the Alliam administrator account first.");
      const response = await fetch(
        "https://europe-west1-spelliam-ad3fd.cloudfunctions.net/buildAudioLibrary",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${await user.getIdToken()}`,
            "Content-Type": "application/json"
          },
          body: JSON.stringify({ data: { wordIds } })
        }
      );
      const payload = await response.json();
      if (!response.ok || payload.error) {
        throw new Error(payload.error?.message || "Audio generation failed.");
      }
      return payload.result;
    },
    async regenerateTestPronunciations() {
      if (!this.configured) throw new Error("Firebase is not configured.");
      initializeFirebase();
      const user = auth.currentUser;
      if (!user) throw new Error("Sign in with the Alliam administrator account first.");
      const response = await fetch(
        "https://europe-west1-spelliam-ad3fd.cloudfunctions.net/regenerateTestPronunciations",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${await user.getIdToken()}`,
            "Content-Type": "application/json"
          },
          body: JSON.stringify({ data: {} })
        }
      );
      const payload = await response.json();
      if (!response.ok || payload.error) {
        throw new Error(payload.error?.message || "Test pronunciation generation failed.");
      }
      return payload.result;
    },
    async regeneratePrimaryPronunciations() {
      if (!this.configured) throw new Error("Firebase is not configured.");
      initializeFirebase();
      const user = auth.currentUser;
      if (!user) throw new Error("Sign in with the Alliam administrator account first.");
      const response = await fetch(
        "https://europe-west1-spelliam-ad3fd.cloudfunctions.net/regeneratePrimaryPronunciations",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${await user.getIdToken()}`,
            "Content-Type": "application/json"
          },
          body: JSON.stringify({ data: {} })
        }
      );
      const payload = await response.json();
      if (!response.ok || payload.error) {
        throw new Error(payload.error?.message || "Primary pronunciation generation failed.");
      }
      return payload.result;
    },
    async approveCoreWordLibrary() {
      if (!this.configured) throw new Error("Firebase is not configured.");
      initializeFirebase();
      const user = auth.currentUser;
      if (!user) throw new Error("Sign in with the Alliam administrator account first.");
      const response = await fetch(
        "https://europe-west1-spelliam-ad3fd.cloudfunctions.net/approveCoreWordLibrary",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${await user.getIdToken()}`,
            "Content-Type": "application/json"
          },
          body: JSON.stringify({ data: {} })
        }
      );
      const payload = await response.json();
      if (!response.ok || payload.error) {
        throw new Error(payload.error?.message || "Word approval failed.");
      }
      return payload.result;
    },
    async generateApprovedNext200Pronunciations() {
      if (!this.configured) throw new Error("Firebase is not configured.");
      initializeFirebase();
      const user = auth.currentUser;
      if (!user) throw new Error("Sign in with the Alliam administrator account first.");
      const response = await fetch(
        "https://europe-west1-spelliam-ad3fd.cloudfunctions.net/generateApprovedNext200Pronunciations",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${await user.getIdToken()}`,
            "Content-Type": "application/json"
          },
          body: JSON.stringify({ data: {} })
        }
      );
      const payload = await response.json();
      if (!response.ok || payload.error) {
        throw new Error(payload.error?.message || "Approved 200-word generation failed.");
      }
      return payload.result;
    },
    async buildAlphabetLibrary() {
      if (!this.configured) throw new Error("Firebase is not configured.");
      initializeFirebase();
      const user = auth.currentUser;
      if (!user) throw new Error("Sign in with the Alliam administrator account first.");
      const response = await fetch(
        "https://europe-west1-spelliam-ad3fd.cloudfunctions.net/buildAlphabetLibrary",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${await user.getIdToken()}`,
            "Content-Type": "application/json"
          },
          body: JSON.stringify({ data: {} })
        }
      );
      const payload = await response.json();
      if (!response.ok || payload.error) {
        throw new Error(payload.error?.message || "Alphabet generation failed.");
      }
      return payload.result;
    },
    async installManualAlphabet(fileList) {
      if (!this.configured) throw new Error("Firebase is not configured.");
      initializeFirebase();
      const user = auth.currentUser;
      if (!user) throw new Error("Sign in with the Alliam administrator account first.");
      const files = {};
      for (const file of Array.from(fileList || [])) {
        const match = /^([a-z])\.mp3$/i.exec(file.name);
        if (!match) continue;
        const bytes = new Uint8Array(await file.arrayBuffer());
        let binary = "";
        for (let offset = 0; offset < bytes.length; offset += 8192) {
          binary += String.fromCharCode(...bytes.subarray(offset, offset + 8192));
        }
        files[match[1].toLowerCase()] = btoa(binary);
      }
      if ("abcdefghijklmnopqrstuvwxyz".split("").some(letter => !files[letter])) {
        throw new Error("Select all 26 files named A.mp3 through Z.mp3.");
      }
      const response = await fetch(
        "https://europe-west1-spelliam-ad3fd.cloudfunctions.net/installManualAlphabet",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${await user.getIdToken()}`,
            "Content-Type": "application/json"
          },
          body: JSON.stringify({ data: { files } })
        }
      );
      const payload = await response.json();
      if (!response.ok || payload.error) {
        throw new Error(payload.error?.message || "Recorded alphabet upload failed.");
      }
      return payload.result;
    },
    async signOut() {
      if (initializeFirebase()) await auth.signOut();
    },
    async deleteAccount() {
      if (!this.configured) return;
      const user = await ensureFirebaseUser();
      await db.doc(`accounts/${user.uid}/data/app-state`).delete();
      await db.doc(`accounts/${user.uid}`).delete();
      await user.delete();
    },
    onAuthStateChanged(callback) {
      if (!initializeFirebase()) { callback(null); return () => {}; }
      return auth.onAuthStateChanged(callback);
    }
  };

  const audio = {
    get configured() { return firebase.configured; },
    player: null,
    alphabet: {},
    setAlphabetLibrary(value = {}) { this.alphabet = value; },
    stop() {
      if ("speechSynthesis" in window) speechSynthesis.cancel();
      if (this.player) {
        this.player.pause();
        this.player.currentTime = 0;
        this.player = null;
      }
    },
    async playWord(entry, speed = "normal") {
      this.stop();
      if (entry.audio?.[speed]) {
        const player = new Audio(entry.audio[speed]);
        this.player = player;
        const finished = new Promise(resolve => {
          player.addEventListener("ended", resolve, { once: true });
          player.addEventListener("error", resolve, { once: true });
        });
        await player.play();
        await finished;
        if (this.player === player) this.player = null;
        return;
      }
      throw new Error(`Recorded audio is unavailable for "${entry.word}".`);
    },
    async speak(text, rate = 0.84) {
      if (!("speechSynthesis" in window)) return;
      await new Promise(resolve => {
        const utterance = new SpeechSynthesisUtterance(text);
        utterance.rate = rate;
        utterance.pitch = 1;
        const voices = speechSynthesis.getVoices();
        utterance.voice = voices.find(v => /^en-(NG|GB|US)/.test(v.lang)) || voices.find(v => /^en/.test(v.lang)) || null;
        utterance.onend = resolve;
        utterance.onerror = resolve;
        speechSynthesis.speak(utterance);
      });
    },
    async playUrl(url) {
      this.stop();
      const player = new Audio(url);
      this.player = player;
      const finished = new Promise(resolve => {
        player.addEventListener("ended", resolve, { once: true });
        player.addEventListener("error", resolve, { once: true });
      });
      await player.play();
      await finished;
      if (this.player === player) this.player = null;
    },
    async spell(word, onLetter) {
      for (let index = 0; index < word.length; index++) {
        onLetter(index);
        const letter = word[index].toLowerCase();
        if (!this.alphabet[letter]) {
          onLetter(-1);
          throw new Error(`Recorded alphabet audio is unavailable for ${letter.toUpperCase()}.`);
        }
        await this.playUrl(this.alphabet[letter]);
        await delay(260);
      }
      onLetter(-1);
    }
  };

  const speech = {
    get configured() { return Boolean(config.microsoftSpeech.enabled); },
    recognizer: null,
    monitor: null,
    tokenCache: null,
    async getCredentials() {
      if (this.tokenCache && Date.now() < this.tokenCache.expiresAt) return this.tokenCache.value;
      const user = await ensureFirebaseUser();
      if (!user) throw new Error("Firebase authentication is required for speech recognition.");
      const tokenResponse = await fetch(config.microsoftSpeech.tokenEndpoint, {
        method: "POST",
        headers: { Authorization: `Bearer ${await user.getIdToken()}` }
      });
      if (!tokenResponse.ok) throw new Error("Alliam could not obtain a Speech authorization token.");
      const value = await tokenResponse.json();
      this.tokenCache = {
        value,
        expiresAt: Date.now() + Math.max(60, (value.expiresInSeconds || 540) - 30) * 1000
      };
      return value;
    },
    async prewarm() {
      if (this.configured && window.SpeechSDK) await this.getCredentials();
    },
    async startMicMonitor({ onAudioStart, onAudioEnd } = {}) {
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: { echoCancellation: true, noiseSuppression: true, autoGainControl: true },
        video: false
      });
      const AudioContextClass = window.AudioContext || window.webkitAudioContext;
      const context = new AudioContextClass();
      if (context.state === "suspended") await context.resume();
      const source = context.createMediaStreamSource(stream);
      const analyser = context.createAnalyser();
      analyser.fftSize = 512;
      analyser.smoothingTimeConstant = 0.35;
      source.connect(analyser);
      const samples = new Float32Array(analyser.fftSize);
      const monitor = {
        stream, context, analyser, samples, frame: 0, enabled: false,
        active: false, quietSince: 0, noiseFloor: 0.006
      };
      this.monitor = monitor;
      const tick = time => {
        if (this.monitor !== monitor) return;
        analyser.getFloatTimeDomainData(samples);
        let energy = 0;
        for (let index = 0; index < samples.length; index++) energy += samples[index] * samples[index];
        const rms = Math.sqrt(energy / samples.length);
        if (!monitor.active) monitor.noiseFloor = monitor.noiseFloor * 0.985 + Math.min(rms, 0.025) * 0.015;
        const threshold = Math.max(0.016, monitor.noiseFloor * 2.8);
        if (monitor.enabled && rms > threshold) {
          monitor.quietSince = 0;
          if (!monitor.active) {
            monitor.active = true;
            onAudioStart?.();
          }
        } else if (monitor.active) {
          if (!monitor.quietSince) monitor.quietSince = time;
          if (time - monitor.quietSince >= 150) {
            monitor.active = false;
            monitor.quietSince = 0;
            onAudioEnd?.();
          }
        }
        monitor.frame = requestAnimationFrame(tick);
      };
      monitor.frame = requestAnimationFrame(tick);
      return monitor;
    },
    async startLetterStream({ locale = "en-NG", onReady, onAudioStart, onAudioEnd, onPartial, onLetters, onError } = {}) {
      if (!this.configured) return { mode: "keyboard", reason: "Microsoft Speech placeholder is not configured." };
      if (!window.SpeechSDK) throw new Error("Microsoft Speech SDK did not load.");

      await this.stop();
      const [credentials, monitor] = await Promise.all([
        this.getCredentials(),
        this.startMicMonitor({ onAudioStart, onAudioEnd })
      ]);
      const sdk = window.SpeechSDK;
      const speechConfig = sdk.SpeechConfig.fromAuthorizationToken(credentials.token, credentials.region);
      speechConfig.speechRecognitionLanguage = locale;
      speechConfig.outputFormat = sdk.OutputFormat.Detailed;
      // Letter spelling is a sequence of very short utterances. Azure's default
      // conversational silence window feels sluggish here, so finalize each
      // letter after a brief pause.
      speechConfig.setProperty(
        sdk.PropertyId.Speech_SegmentationSilenceTimeoutMs,
        "350"
      );
      speechConfig.setProperty(
        sdk.PropertyId.SpeechServiceConnection_EndSilenceTimeoutMs,
        "350"
      );
      speechConfig.setProperty(
        sdk.PropertyId.SpeechServiceConnection_InitialSilenceTimeoutMs,
        "8000"
      );

      const audioConfig = sdk.AudioConfig.fromDefaultMicrophoneInput();
      const recognizer = new sdk.SpeechRecognizer(speechConfig, audioConfig);
      this.recognizer = recognizer;

      const phrases = sdk.PhraseListGrammar.fromRecognizer(recognizer);
      phrases.addPhrases([
        ..."abcdefghijklmnopqrstuvwxyz",
        "ay", "bee", "cee", "dee", "ee", "letter e", "e as in eagle",
        "eff", "gee", "aitch", "eye",
        "jay", "kay", "el", "elle", "em", "en", "oh", "pee", "cue",
        "are", "ess", "tee", "you", "vee", "double you", "ex", "why",
        "zee", "zed"
      ]);
      phrases.setWeight(2);

      let emittedInUtterance = 0;
      recognizer.recognizing = (_sender, event) => {
        if (!event.result?.text) return;
        onPartial?.(event.result.text);
        const partialLetters = this.normalizeLetters(event.result.text);
        if (partialLetters.length > emittedInUtterance) {
          const newLetters = partialLetters.slice(emittedInUtterance);
          const accepted = onLetters?.(
            newLetters,
            event.result.text,
            { interim: true }
          );
          emittedInUtterance += Number.isInteger(accepted) ? accepted : newLetters.length;
        }
      };
      recognizer.recognized = (_sender, event) => {
        if (event.result.reason === sdk.ResultReason.NoMatch) {
          emittedInUtterance = 0;
          return;
        }
        if (event.result.reason !== sdk.ResultReason.RecognizedSpeech) return;
        let letters = this.normalizeLetters(event.result.text);
        if (!letters.length) {
          letters = this.normalizeDetailedAlternatives(event.result, sdk);
        }
        if (letters.length > emittedInUtterance) {
          const newLetters = letters.slice(emittedInUtterance);
          const accepted = onLetters?.(
            newLetters,
            event.result.text,
            { interim: false }
          );
          emittedInUtterance += Number.isInteger(accepted) ? accepted : newLetters.length;
        } else if (event.result.text) {
          if (!letters.length) {
            onError?.(new Error(`I heard “${event.result.text}”. Please repeat that letter.`));
          }
        }
        emittedInUtterance = 0;
      };
      recognizer.canceled = (_sender, event) => {
        if (event.reason === sdk.CancellationReason.Error) {
          onError?.(new Error(event.errorDetails || "Speech recognition was canceled."));
        }
        this.stop();
      };

      await new Promise((resolve, reject) => {
        recognizer.startContinuousRecognitionAsync(resolve, reject);
      });
      monitor.enabled = true;
      onReady?.();
      return { mode: "speech", stop: () => this.stop() };
    },
    async stop() {
      const recognizer = this.recognizer;
      this.recognizer = null;
      const monitor = this.monitor;
      this.monitor = null;
      if (monitor) {
        cancelAnimationFrame(monitor.frame);
        monitor.stream.getTracks().forEach(track => track.stop());
        await monitor.context.close().catch(() => {});
      }
      if (recognizer) {
        await new Promise(resolve => {
          recognizer.stopContinuousRecognitionAsync(
            () => { recognizer.close(); resolve(); },
            () => { recognizer.close(); resolve(); }
          );
        });
      }
    },
    normalizeLetters(value) {
      const cleaned = String(value)
        .toLowerCase()
        .replace(/[’']/g, "")
        .replace(/[.,!?;:]/g, " ")
        .replace(/\bdouble\s+you\b/g, "double-you")
        .trim();
      if (!cleaned) return [];
      return cleaned
        .split(/\s+/)
        .map(token => this.normalizeLetter(token.replace("-", " ")))
        .filter(Boolean);
    },
    normalizeDetailedAlternatives(result, sdk) {
      try {
        const raw = result.properties.getProperty(
          sdk.PropertyId.SpeechServiceResponse_JsonResult
        );
        const details = JSON.parse(raw || "{}");
        const alternatives = Array.isArray(details.NBest) ? details.NBest : [];
        for (const alternative of alternatives) {
          for (const candidate of [
            alternative.Display,
            alternative.Lexical,
            alternative.ITN,
            alternative.MaskedITN
          ]) {
            const letters = this.normalizeLetters(candidate);
            if (letters.length) return letters;
          }
        }
      } catch (_error) {}
      return [];
    },
    normalizeLetter(value) {
      const aliases = { ay:"a", hey:"a", a:"a", bee:"b", be:"b", b:"b", see:"c", sea:"c", c:"c", dee:"d", the:"d", d:"d", e:"e", ee:"e", eel:"e", he:"e", ease:"e", east:"e", eff:"f", f:"f", gee:"g", g:"g", aitch:"h", h:"h", eye:"i", i:"i", jay:"j", j:"j", kay:"k", k:"k", el:"l", elle:"l", hell:"l", l:"l", em:"m", am:"m", im:"m", m:"m", en:"n", and:"n", n:"n", oh:"o", o:"o", pea:"p", pee:"p", p:"p", cue:"q", queue:"q", q:"q", are:"r", r:"r", ess:"s", s:"s", tea:"t", tee:"t", t:"t", you:"u", u:"u", vee:"v", v:"v", "double you":"w", w:"w", ex:"x", x:"x", why:"y", y:"y", zee:"z", zed:"z", z:"z" };
      return aliases[String(value).toLowerCase().trim()] || "";
    }
  };

  window.AlliamServices = { firebase, audio, speech, delay };
})();
