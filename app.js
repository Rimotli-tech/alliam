(function () {
  const services = window.AlliamServices;
  const STORAGE_KEY = "alliam-product-state-v010";
  const LEGACY_STORAGE_KEY = "spelliam-product-state-v010";
  const AUDIO_CACHE_KEY = "alliam-audio-library-v1";

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
    { word:"prestidigitation", level:"Championship", definition:"Magic performed with skilful movements of the hands.", sentence:"The magician's prestidigitation astonished the audience.", origin:"French", part:"noun" }
  ];

  const seedLeaderboard = [
    ["Amina K.","Nigeria",1840,38],["Kwame A.","Ghana",1795,34],["Lerato M.","South Africa",1732,30],
    ["David O.","Nigeria",1684,27],["Zuri N.","Kenya",1610,25],["Tobi A.","Nigeria",1548,22],["Maya E.","Ghana",1489,20]
  ];

  const defaultState = {
    initialized:false,
    activeProfileId:null,
    profiles:[],
    role:"student",
    score:0,
    rank:1320,
    streak:0,
    trainingSessions:0,
    matches:[],
    reviewWords:["rhythm","necessary"],
    friends:[],
    teams:[],
    events:[],
    customWords:[],
    notifications:[{id:1,text:"Tobi challenged you to a friendly match.",type:"invite",read:false},{id:2,text:"Your daily challenge is ready.",type:"daily",read:false}],
    settings:{learnerLevel:"Foundation",voice:"Alliam One",speed:"Normal",volume:90,locale:"en-NG",effects:true,reducedMotion:false,highContrast:false,matchAlerts:true,inviteAlerts:true,rankAlerts:true,profileVisibility:"School & friends",friendRequests:true,audioRetention:false},
    serviceMode:"mock"
  };

  let state = loadState();
  let runtime = { authMode:"signin", authBusy:false, audioStatus:"idle", audioError:"", alphabetReady:0, onboardingStep:0, onboarding:{role:"student",nickname:"",guardianName:"",learnerName:"",schoolName:"",adminName:"",grade:"Grade 1",country:"Nigeria",school:"",avatar:"A"}, trainingSetup:{mode:"Hear & Spell",level:"Foundation",count:5,assistance:"Guided"}, session:null, competition:null, modal:null, tab:null, mobileMenu:false, profileMenu:false, viewedLearnerId:null, live:{player:null,leaderboard:[],friendRequests:[],friends:[],teams:[],events:[],invitations:[]}, liveUnsubscribe:null, matchUnsubscribe:null, sidebarCollapsed:true };

  const routes = {
    home:"Home", train:"Train", compete:"Compete", rankings:"Rankings", social:"Friends & teams", profile:"Profile",
    settings:"Settings", parent:"Parent dashboard", school:"School hub", admin:"Content & administration", notifications:"Notifications"
  };

  const iconPaths = {
    home:'<path d="m3 11 9-8 9 8"/><path d="M5 10v10h14V10"/><path d="M9 20v-6h6v6"/>',
    dumbbell:'<path d="M6.5 6.5v11M17.5 6.5v11M3 9v6M21 9v6M6.5 12h11"/>',
    swords:'<path d="m14.5 17.5 3 3 3-3-3-3M4 3l13.5 13.5M9.5 17.5l-3 3-3-3 3-3M20 3 6.5 16.5"/>',
    chart:'<path d="M4 19V9M10 19V5M16 19v-7M22 19V3"/>',
    users:'<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/>',
    user:'<circle cx="12" cy="8" r="4"/><path d="M4 21a8 8 0 0 1 16 0"/>',
    settings:'<circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06-2.83 2.83-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21h-4v-.09a1.65 1.65 0 0 0-1-1.51 1.65 1.65 0 0 0-1.82.33l-.06.06-2.83-2.83.06-.06A1.65 1.65 0 0 0 4.6 15a1.65 1.65 0 0 0-1.51-1H3v-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06 2.83-2.83.06.06A1.65 1.65 0 0 0 8.92 4a1.65 1.65 0 0 0 1-1.51V2h4v.09A1.65 1.65 0 0 0 15 3.6a1.65 1.65 0 0 0 1.82-.33l.06-.06 2.83 2.83-.06.06A1.65 1.65 0 0 0 19.4 9c.12.6.65 1 1.27 1H21v4h-.09c-.62 0-1.15.4-1.51 1Z"/>',
    bell:'<path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4"/>',
    menu:'<path d="M4 6h16M4 12h16M4 18h16"/>', play:'<path d="m8 5 11 7-11 7Z"/>',
    mic:'<rect x="9" y="2" width="6" height="12" rx="3"/><path d="M5 10a7 7 0 0 0 14 0M12 17v5M8 22h8"/>',
    refresh:'<path d="M20 6v6h-6"/><path d="M20 12a8 8 0 1 0-2.34 5.66"/>', skip:'<path d="m5 4 10 8-10 8ZM19 5v14"/>',
    trophy:'<path d="M8 21h8M12 17v4M7 4h10v5a5 5 0 0 1-10 0ZM7 6H4v2a4 4 0 0 0 4 4M17 6h3v2a4 4 0 0 1-4 4"/>',
    clock:'<circle cx="12" cy="12" r="9"/><path d="M12 7v5l3 2"/>', flag:'<path d="M5 21V4M5 5h11l-2 4 2 4H5"/>',
    plus:'<path d="M12 5v14M5 12h14"/>', search:'<circle cx="11" cy="11" r="7"/><path d="m20 20-4-4"/>',
    chevron:'<path d="m9 18 6-6-6-6"/>', check:'<path d="m5 12 4 4L19 6"/>', x:'<path d="m6 6 12 12M18 6 6 18"/>',
    school:'<path d="m3 10 9-5 9 5-9 5Z"/><path d="M7 12v5c3 2 7 2 10 0v-5M21 10v6"/>',
    shield:'<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10Z"/>', database:'<ellipse cx="12" cy="5" rx="8" ry="3"/><path d="M4 5v6c0 1.7 3.6 3 8 3s8-1.3 8-3V5M4 11v6c0 1.7 3.6 3 8 3s8-1.3 8-3v-6"/>',
    logout:'<path d="M10 17l5-5-5-5M15 12H3M15 3h5v18h-5"/>', volume:'<path d="M11 5 6 9H2v6h4l5 4ZM15 9a4 4 0 0 1 0 6M18 6a8 8 0 0 1 0 12"/>',
    eye:'<path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/>',
    lock:'<rect x="4" y="10" width="16" height="11" rx="2"/><path d="M8 10V7a4 4 0 0 1 8 0v3"/>',
    help:'<circle cx="12" cy="12" r="10"/><path d="M9.1 9a3 3 0 1 1 5.8 1c0 2-3 2-3 4M12 18h.01"/>',
    inbox:'<path d="M4 4h16v16H4Z"/><path d="M4 14h4l2 3h4l2-3h4"/>',
    upload:'<path d="M12 16V4M7 9l5-5 5 5M4 20h16"/>',
    edit:'<path d="M12 20h9M16.5 3.5a2.1 2.1 0 0 1 3 3L8 18l-4 1 1-4Z"/>'
  };

  function icon(name, label="") { return `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" ${label ? `aria-label="${label}" role="img"` : 'aria-hidden="true"'}>${iconPaths[name] || iconPaths.help}</svg>`; }
  function migrateBrandState(value){
    const migrated={...value};
    if(migrated.settings?.voice)migrated.settings={...migrated.settings,voice:migrated.settings.voice.replace(/^Spelliam/,'Alliam')};
    // Early parent accounts can have a stale `student` role in Firebase even
    // though their account-owner record and learner profiles are intact.
    if(migrated.accountOwner&&migrated.role!=='school')migrated.role='parent';
    return migrated;
  }
  function isParentAccount(){return state.role==='parent'||Boolean(state.accountOwner);}
  function isSchoolAccount(){return state.role==='school'||Boolean(state.schoolAccount);}
  function accountLandingRoute(){return isParentAccount()?'parent':isSchoolAccount()?'school':'home';}
  function loadState(){ try { const saved=localStorage.getItem(STORAGE_KEY) || localStorage.getItem(LEGACY_STORAGE_KEY) || "{}"; const loaded=migrateBrandState({ ...defaultState, ...JSON.parse(saved) }); if(!localStorage.getItem(STORAGE_KEY)&&saved!=="{}")localStorage.setItem(STORAGE_KEY,JSON.stringify(loaded)); return loaded; } catch { return structuredClone(defaultState); } }
  function saveState(){
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    if(services.firebase.configured)return services.firebase.save('app-state',state).catch(error=>console.warn('Firebase sync failed:',error.message));
    return Promise.resolve();
  }
  function profile(){
    const stored=state.profiles.find(p => p.id === state.activeProfileId) || state.profiles[0] || {id:"guest",nickname:"Speller",grade:"Grade 1",country:"Nigeria",avatar:"S",school:""};
    const user=services.firebase.user;
    if(isParentAccount())return stored;
    if(!user||user.isAnonymous)return stored;
    const nickname=(user.displayName||user.email?.split('@')[0]||stored.nickname).trim();
    return {...stored,nickname,avatar:(nickname[0]||stored.avatar||'S').toUpperCase()};
  }
  function accountIdentity(){
    if(isSchoolAccount()){
      const school=state.schoolAccount||{},name=school.adminName||services.firebase.user?.displayName||school.name||'School administrator';
      return {nickname:name,avatar:initials(name),grade:school.name||'School account',country:school.country||'Nigeria'};
    }
    if(!isParentAccount())return profile();
    const user=services.firebase.user,owner=state.accountOwner||{};
    const name=(owner.name||user?.displayName||user?.email?.split('@')[0]||'Parent').trim();
    return {nickname:name,avatar:owner.avatar||initials(name),grade:'Parent account',country:owner.country||'Nigeria'};
  }
  function syncAuthenticatedIdentity(value,user){
    const next=migrateBrandState({...defaultState,...value});
    if(!user||user.isAnonymous)return next;
    const displayName=(user.displayName||user.email?.split('@')[0]||'').trim();
    if(!displayName)return next;
    if(next.role==='parent'||next.accountOwner)return {...next,role:'parent',accountOwner:{...(next.accountOwner||{}),name:next.accountOwner?.name||displayName}};
    const profiles=[...(next.profiles||[])];
    const index=Math.max(0,profiles.findIndex(item=>item.id===next.activeProfileId));
    if(profiles[index])profiles[index]={...profiles[index],nickname:displayName,avatar:(displayName[0]||profiles[index].avatar||'A').toUpperCase()};
    else{
      const accountProfile={id:`account-${user.uid}`,nickname:displayName,grade:'Grade 1',country:'Nigeria',school:'',avatar:displayName[0].toUpperCase()};
      profiles.push(accountProfile);next.activeProfileId=accountProfile.id;
    }
    return {...next,profiles};
  }
  function allWords(){const merged=new Map(WORDS.map(word=>[word.word,word]));(state.customWords||[]).forEach(word=>merged.set(word.word,word));return [...merged.values()];}
  async function hydrateAudioLibrary({retries=3}={}){
    if(runtime.audioStatus==='loading'&&runtime.audioLoadPromise)return runtime.audioLoadPromise;
    runtime.audioStatus='loading';runtime.audioError='';render();
    runtime.audioLoadPromise=(async()=>{
      let lastError;
      for(let attempt=1;attempt<=retries;attempt++){
        try{
          const [library,alphabet]=await Promise.all([
            services.firebase.loadWordAudio(WORDS.map(entry=>entry.word)),
            services.firebase.loadAlphabetAudio()
          ]);
          const alphabetCount="abcdefghijklmnopqrstuvwxyz".split("").filter(letter=>alphabet[letter]).length;
          if(alphabetCount!==26)throw new Error(`Only ${alphabetCount} of 26 alphabet recordings loaded.`);
          const missingWords=WORDS.filter(entry=>!library[entry.word]?.normal);
          if(missingWords.length)throw new Error(`${missingWords.length} word recording${missingWords.length===1?' is':'s are'} unavailable.`);
          for(const entry of WORDS)entry.audio=library[entry.word];
          services.audio.setAlphabetLibrary(alphabet);
          localStorage.setItem(AUDIO_CACHE_KEY,JSON.stringify({library,alphabet,cachedAt:Date.now()}));
          runtime.alphabetReady=alphabetCount;runtime.audioStatus='ready';runtime.audioError='';
          render();return true;
        }catch(error){
          lastError=error;
          if(attempt<retries)await services.delay(attempt*700);
        }
      }
      services.audio.setAlphabetLibrary({});
      runtime.alphabetReady=0;runtime.audioStatus='error';
      runtime.audioError=lastError?.message||'Recorded audio could not be loaded.';
      render();throw lastError;
    })().finally(()=>{runtime.audioLoadPromise=null;});
    return runtime.audioLoadPromise;
  }
  function restoreCachedAudioLibrary(){
    try{
      const cached=JSON.parse(localStorage.getItem(AUDIO_CACHE_KEY)||'null');
      if(!cached?.library||!cached?.alphabet)return false;
      const alphabetCount="abcdefghijklmnopqrstuvwxyz".split("").filter(letter=>cached.alphabet[letter]).length;
      const complete=alphabetCount===26&&WORDS.every(entry=>cached.library[entry.word]?.normal);
      if(!complete)return false;
      for(const entry of WORDS)entry.audio=cached.library[entry.word];
      services.audio.setAlphabetLibrary(cached.alphabet);
      runtime.alphabetReady=26;runtime.audioStatus='ready';runtime.audioError='';
      return true;
    }catch{return false;}
  }
  function warmAudioInBackground(){
    if(!services.firebase.user||services.firebase.user.isAnonymous)return;
    if(['loading','ready'].includes(runtime.audioStatus))return;
    hydrateAudioLibrary({retries:3}).catch(error=>console.warn('Background audio preparation failed:',error.message));
  }
  async function ensureRecordedAudio(){
    if(runtime.audioStatus==='ready'&&runtime.alphabetReady===26)return true;
    if(!services.firebase.user){
      runtime.audioStatus='error';runtime.audioError='Sign in to load the recorded audio.';render();
      return false;
    }
    try{return await hydrateAudioLibrary({retries:3});}
    catch(error){toast(`Recorded audio unavailable: ${runtime.audioError}`);return false;}
  }
  function initials(name){ return String(name || "S").split(/\s+/).map(x=>x[0]).join("").slice(0,2).toUpperCase(); }
  function toast(message){ const region=document.querySelector("#toastRegion"); const el=document.createElement("div"); el.className="toast"; el.textContent=message; region.appendChild(el); setTimeout(()=>el.remove(),2600); }
  function navigate(destination){
    services.speech.stop();
    if(destination==='landing'){
      if(location.protocol==='http:'||location.protocol==='https:'){history.pushState({},'', '/landing');location.hash='';render();}
      else location.hash='landing';
      return;
    }
    if(location.pathname==='/landing') history.replaceState({},'', '/');
    location.hash=destination;
  }

  function enterTrainingLetter(letter,source='speech'){
    if(runtime.session?.phase!=='attempt')return false;
    const s=runtime.session,e=s.words[s.index];
    const expected=s.expectedAnswer||e.word;
    if(s.attempt.length>=expected.length)return false;
    if(source==='typing'){
      s.attempt.push(letter);
      s.heardFeedback=null;
      render();
      return true;
    }
    if(s.heardFeedback){s.pendingHeardLetters=[...(s.pendingHeardLetters||[]),letter];return true;}
    const index=s.attempt.length,correct=letter===expected[index],feedbackId=Date.now();
    s.heardFeedback={index,correct,letter,id:feedbackId};
    if(correct)s.attempt.push(letter);
    render();
    setTimeout(()=>{
      if(runtime.session!==s||s.heardFeedback?.id!==feedbackId)return;
      s.heardFeedback=null;
      if(s.attempt.length===expected.length){
        services.speech.stop();
        recordTrainingAttempt(s.attempt.join('')===expected,s.attempt.join(''));
      }else if(s.pendingHeardLetters?.length){
        const next=s.pendingHeardLetters.shift();
        enterTrainingLetter(next);
      }else render();
    },420);
    return true;
  }

  function enterCompetitionLetter(letter){
    const m=runtime.competition;
    if(!m||m.phase!=='playing'||m.attempt.length>=m.word.word.length)return false;
    if(m.heardFeedback){m.pendingHeardLetters=[...(m.pendingHeardLetters||[]),letter];return true;}
    const index=m.attempt.length,correct=letter===m.word.word[index],feedbackId=Date.now();
    m.attempt.push(letter);
    m.heardFeedback={index,correct,letter,id:feedbackId};
    render();
    setTimeout(()=>{if(runtime.competition===m&&m.heardFeedback?.id===feedbackId){m.heardFeedback=null;if(m.pendingHeardLetters?.length)enterCompetitionLetter(m.pendingHeardLetters.shift());else render();}},420);
    return true;
  }

  async function startSpeechAttempt(){
    const isMatch=route()==='match'&&runtime.competition?.phase==='playing'&&runtime.competition.turn==='player';
    const isTraining=route()==='train-session'&&runtime.session?.phase==='attempt';
    if(!isMatch&&!isTraining)return;
    const listeningState=isTraining?runtime.session:runtime.competition;
    listeningState.micConnecting=true;
    listeningState.micListening=false;
    listeningState.micActivityId=null;
    render();
    try{
      toast('Listening… spell one letter at a time.');
      await services.speech.startLetterStream({
        locale:state.settings.locale,
        onReady:()=>{
          const target=isTraining?runtime.session:runtime.competition;
          if(!target)return;
          target.micConnecting=false;
          target.micListening=true;
          render();
        },
        onAudioStart:()=>{
          const target=isTraining?runtime.session:runtime.competition;
          if(!target)return;
          const activityId=Date.now();
          target.micActivityId=activityId;
          render();
        },
        onAudioEnd:()=>{
          const target=isTraining?runtime.session:runtime.competition;
          if(!target)return;
          target.micActivityId=null;
          render();
        },
        onPartial:()=>{},
        onLetters:letters=>{
          let accepted=0;
          for(const letter of letters){
            if(isTraining){
              if(enterTrainingLetter(letter))accepted++;
            }
            else if(enterCompetitionLetter(letter))accepted++;
          }
          return accepted;
        },
        onError:error=>{listeningState.micConnecting=false;listeningState.micListening=false;listeningState.micActivityId=null;toast(error.message||'Microphone recognition stopped.');render();}
      });
    }catch(error){
      listeningState.micConnecting=false;
      listeningState.micListening=false;
      listeningState.micActivityId=null;
      toast(error.message||'Speech recognition is unavailable. Use the keyboard.');
      render();
    }
  }
  function route(){ if(location.pathname==='/landing')return 'landing';return (location.hash.replace("#","") || (state.initialized?"home":"landing")).split("?")[0]; }

  function render(){
    services.audio.stop();
    const app=document.querySelector("#app");
    const current=route();
    if(current==='landing'){app.innerHTML=renderLanding();bindIcons();return;}
    if(current==='auth'){app.innerHTML=renderAuth();bindIcons();return;}
    if(!state.initialized){
      if(current!=='onboarding'){navigate('landing');return;}
      app.innerHTML=renderOnboarding();bindIcons();return;
    }
    if(['train-session','match','match-result'].includes(current)){
      let workView=renderRoute(current);
      if(current==='match')workView=workView.replace('<button class="train-logo" data-nav="home">All<span>iam</span></button>',`<button class="work-exit" data-nav="compete" aria-label="Back to competition modes" title="Back to competition modes">${icon('home')}</button>`);
      app.innerHTML=workView+(runtime.modal?renderModal():'');bindIcons();return;
    }
    const body=renderRoute(current);
    app.innerHTML=renderShell(current,body);
    bindIcons();
  }

  function renderLanding(){
    const features=[
      ['dumbbell','Adaptive practice','Word difficulty adjusts to recent performance so every session stays challenging.','orange'],
      ['swords','Live competitions','Ranked matches, private school rooms, and open tournaments.','coral'],
      ['chart','Global rankings','School, regional, national, and friends-only leaderboards.','violet'],
      ['users','Team tournaments','Relay formats let schools field teams and track cumulative scores.','blue'],
      ['clock','Progress reports','Accuracy, response time, pressure stats, and personal review lists.','green'],
      ['shield','Safe profiles','School-managed permissions with no open student messaging.','violet']
    ];
    return `<div class="landing-page">
      <section class="landing-hero">
        <img class="landing-vector-bg" src="assets/hero-background-vectors.svg" alt="" aria-hidden="true" />
        <div class="landing-grid-lines" aria-hidden="true"></div>
        <div class="landing-orb orb-two" aria-hidden="true"></div>
        <header class="landing-header">
          <button class="landing-logo" data-action="landing-home" aria-label="Alliam home"><span>All</span><b>iam</b></button>
          <nav class="landing-nav" aria-label="Public navigation">
            <button data-scroll="how-it-works">How It Works</button><button data-action="landing-train">Train</button><button data-action="landing-compete">Compete</button><button data-scroll="schools">Schools</button>
          </nav>
          <div class="landing-account"><button class="landing-signin" data-action="landing-signin">${state.initialized?'Open app':'Sign In'}</button><button class="landing-pill" data-action="landing-start">Start Spelling</button></div>
          <button class="landing-menu" data-action="landing-menu" aria-label="Open navigation">${icon('menu')}</button>
        </header>
        <div class="landing-hero-inner">
          <div class="landing-copy">
            <h1>Train your spelling.<span class="headline-line"><em>Step up</em> to compete.</span></h1>
            <p>Practise competition words, build confidence under pressure, and challenge spellers from your school and beyond.</p>
            <div class="landing-actions"><button class="landing-primary" data-action="landing-start">Start spelling <i>${icon('chevron')}</i></button><button class="landing-secondary" data-action="landing-compete">Explore competitions ${icon('chevron')}</button></div>
          </div>
          <div class="landing-hero-art"><div class="hero-art-glow" aria-hidden="true"></div><img src="assets/alliam-abc-3d.png" alt="Three dimensional letters A, B and C" /></div>
        </div>
      </section>

      <main class="landing-main">
        <section class="landing-how" id="how-it-works">
          <div class="landing-steps"><div class="landing-eyebrow">HOW IT WORKS</div><h2>From first word<br>to first place.</h2>
            ${[['01','Choose your level','Select word lists by grade or competition category.'],['02','Train under pressure','Hear words, request information, and practise under real match rules.'],['03','Enter live matches','Compete in ranked 1v1, school tournaments, or team relays.'],['04','Track your ascent','Rankings, accuracy, and review lists show every improvement.']].map(([n,t,c])=>`<article class="landing-step"><b>${n}</b><div><h3>${t}</h3><p>${c}</p></div></article>`).join('')}
          </div>
          <div class="landing-feature-grid">${features.map(([ico,title,copy,tone])=>`<article class="landing-feature"><span class="feature-icon ${tone}">${icon(ico)}</span><h3>${title}</h3><p>${copy}</p></article>`).join('')}</div>
        </section>

        <section class="landing-school" id="schools"><div><div class="landing-eyebrow">FOR SCHOOLS & TEAMS</div><h2>Run serious spelling competition—without the administrative scramble.</h2><p>Create private rooms, manage safe learner profiles, field teams, and follow performance from practice to tournament day.</p><button class="landing-primary dark" data-action="landing-start">Set up your school ${icon('chevron')}</button></div><div class="school-scorecard"><div class="scorecard-top"><span>INTER-SCHOOL WARM-UP</span><b>LIVE</b></div><div class="school-versus"><span><i>EG</i> Emerald Grammar</span><strong>4 <small>—</small> 3</strong><span><i>KA</i> Kings Academy</span></div><div class="school-progress"><span style="width:72%"></span></div><p>Round 8 of 10 · Championship division</p></div></section>

        <section class="landing-final"><div class="final-orb" aria-hidden="true"></div><div class="landing-eyebrow">READY WHEN YOU ARE</div><h2>Your next word is waiting.</h2><p>Build a stronger spelling routine and be ready when the competition begins.</p><button class="landing-primary" data-action="landing-start">Create an Alliam profile ${icon('chevron')}</button></section>
      </main>
      <footer class="landing-footer"><button class="landing-logo dark-logo" data-action="landing-home"><span>All</span><b>iam</b></button><p>Competition-focused spelling for learners, families, schools, and teams.</p><div><button data-scroll="how-it-works">How It Works</button><button data-action="landing-train">Train</button><button data-action="landing-compete">Compete</button><button data-scroll="schools">Schools</button></div><small>© ${new Date().getFullYear()} Alliam</small></footer>
    </div>`;
  }

  function renderAuth(){
    const signup=runtime.authMode==='signup';
    return `<main class="auth-page"><section class="auth-brand"><button class="landing-logo" data-action="landing-home"><span>All</span><b>iam</b></button><div><span class="auth-mark">${icon(signup?'user':'lock')}</span><h1>${signup?'Ready to rise?':'Welcome back'}</h1><p>${signup?'Create one secure account for training, competitions, and progress.':'Continue your spelling journey.'}</p></div></section><section class="auth-panel"><form class="auth-card" id="authForm"><button type="button" class="auth-back" data-action="landing-home">${icon('chevron')}<span>Home</span></button><div class="auth-heading"><small>${signup?'CREATE ACCOUNT':'SIGN IN'}</small><h2>${signup?'Join Alliam':'Your account'}</h2></div>${signup?`<div class="field"><label for="authName">Name</label><input class="input" id="authName" autocomplete="name" required placeholder="Ada" /></div>`:''}<div class="field"><label for="authEmail">Email</label><input class="input" id="authEmail" type="email" autocomplete="email" required placeholder="name@example.com" /></div><div class="field"><label for="authPassword">Password</label><input class="input" id="authPassword" type="password" autocomplete="${signup?'new-password':'current-password'}" minlength="6" required placeholder="At least 6 characters" /></div><button class="auth-submit" type="submit" ${runtime.authBusy?'disabled':''}>${runtime.authBusy?'Please wait…':signup?'Create account':'Sign in'} ${icon('chevron')}</button><button class="auth-switch" type="button" data-action="toggle-auth-mode">${signup?'Already have an account? Sign in':'New to Alliam? Create an account'}</button><div class="auth-divider"><span>or</span></div><button class="auth-demo" type="button" data-action="load-demo">${icon('play')} Explore with a demo profile</button></form></section></main>`;
  }

  function renderOnboarding(){
    const o=runtime.onboarding;
    const roleStep=`<h2>Choose how you’ll use Alliam</h2><p>This determines the experience we prepare.</p><div class="role-grid">${[["student","user","Student"],["parent","shield","Parent"],["school","school","School"]].map(([value,ico,label])=>`<button class="role-option ${o.role===value?'active':''}" data-onboard-role="${value}"><span>${icon(ico)}</span><strong>${label}</strong></button>`).join("")}</div>`;
    const learnerStep=(heading='Create the learner profile')=>`<h2>${heading}</h2><p>Only the essentials for fair, age-appropriate competition.</p><div class="form"><div class="field"><label for="obName">First name or competition nickname</label><input class="input" id="obName" value="${o.role==='parent'?o.learnerName:o.nickname}" placeholder="e.g. Ada" /></div><div class="grid grid-2"><div class="field"><label for="obGrade">Grade</label><select class="select" id="obGrade">${[1,2,3,4,5,6,7,8].map(n=>`<option ${o.grade===`Grade ${n}`?'selected':''}>Grade ${n}</option>`).join("")}</select></div><div class="field"><label for="obCountry">Country</label><select class="select" id="obCountry">${['Nigeria','Ghana','Kenya','South Africa','Other'].map(country=>`<option ${o.country===country?'selected':''}>${country}</option>`).join('')}</select></div></div><div class="field"><label for="obSchool">School (optional)</label><input class="input" id="obSchool" value="${o.school}" placeholder="Your school" /></div><div class="field"><label>Profile initial</label><div class="avatar-grid">${["A","S","K","Z","T"].map(x=>`<button class="avatar-choice ${o.avatar===x?'active':''}" data-avatar="${x}">${x}</button>`).join("")}</div></div></div>`;
    const parentStep=`<h2>Create the parent profile</h2><p>This adult account manages learners, permissions, and progress.</p><div class="form"><div class="field"><label for="obGuardianName">Parent or guardian name</label><input class="input" id="obGuardianName" value="${o.guardianName||o.nickname}" placeholder="Your name" /></div><div class="field"><label for="obCountry">Country</label><select class="select" id="obCountry">${['Nigeria','Ghana','Kenya','South Africa','Other'].map(country=>`<option ${o.country===country?'selected':''}>${country}</option>`).join('')}</select></div></div>`;
    const schoolStep=`<h2>Set up your school</h2><p>Create the institution account used for rosters, teams, fixtures, and competitions.</p><div class="form"><div class="field"><label for="obSchoolName">School or organisation name</label><input class="input" id="obSchoolName" value="${o.schoolName||''}" placeholder="e.g. Emerald Primary School" /></div><div class="field"><label for="obAdminName">Administrator or coach name</label><input class="input" id="obAdminName" value="${o.adminName||o.nickname||''}" placeholder="Your name" /></div><div class="field"><label for="obCountry">Country</label><select class="select" id="obCountry">${['Nigeria','Ghana','Kenya','South Africa','Other'].map(country=>`<option ${o.country===country?'selected':''}>${country}</option>`).join('')}</select></div></div>`;
    const soundStep=`<h2>Check your sound</h2><p>Alliam needs clear playback and a microphone for voice-first spelling.</p><div class="card"><div class="list-row"><div class="card-icon">${icon('volume')}</div><div class="list-main"><strong>Speaker</strong><small>Hear the sample word clearly.</small></div><button class="btn btn-sm" data-action="speaker-test">Test</button></div><div class="list-row"><div class="card-icon">${icon('mic')}</div><div class="list-main"><strong>Microphone</strong><small>${services.speech.configured?'Say a letter to verify recognition.':'Speech service is not connected.'}</small></div><button class="btn btn-sm" data-action="mic-test" ${services.speech.configured?'':'disabled'}>${services.speech.configured?'Test':'Unavailable'}</button></div></div><div class="switch-row"><div><strong>Parent or guardian consent</strong><div class="muted">Required for voice features on a child account.</div></div><label class="switch"><input id="consentCheck" type="checkbox" checked/><span></span></label></div>`;
    const learnerName=o.role==='parent'?o.learnerName:o.nickname;
    const readyStep=o.role==='parent'
      ? `<h2>Your family is ready</h2><p>You can add and manage more learners from the Parent dashboard at any time.</p><div class="card"><div class="list-row"><span class="avatar">${o.avatar}</span><div class="list-main"><strong>${learnerName||'First learner'}</strong><small>${o.grade} · ${o.country}</small></div></div><div class="list-row"><span class="card-icon">${icon('plus')}</span><div class="list-main"><strong>More learner profiles</strong><small>Add siblings or other learners after setup.</small></div></div></div>`
      : o.role==='school'
      ? `<h2>Your school hub is ready</h2><p>Add learners and staff after entering the hub, then organise teams and fixtures.</p><div class="card"><div class="list-row"><span class="avatar">${initials(o.schoolName||'School')}</span><div class="list-main"><strong>${o.schoolName||'Your school'}</strong><small>${o.country} · Managed by ${o.adminName||'Administrator'}</small></div></div><div class="list-row"><span class="card-icon">${icon('users')}</span><div class="list-main"><strong>Build your roster</strong><small>Learner profiles belong inside the school account—not to the administrator.</small></div></div></div>`
      : `<h2>You’re ready to spell</h2><p>Your journey starts with Foundation words and adapts as you compete.</p><div class="card"><div class="list-row"><span class="avatar">${o.avatar}</span><div class="list-main"><strong>${learnerName||'New speller'}</strong><small>${o.grade} · ${o.country}</small></div></div><div class="progress-label"><span>Starting level</span><strong>Foundation</strong></div><div class="progress"><span style="width:20%"></span></div></div>`;
    const steps=o.role==='parent'
      ? [roleStep,parentStep,learnerStep('Add the first learner'),soundStep,readyStep]
      : o.role==='school'
      ? [roleStep,schoolStep,readyStep]
      : [roleStep,learnerStep(),soundStep,readyStep];
    return `<div class="onboarding"><aside class="onboarding-side"><div class="brand"><b class="brand-mark">A</b><span>Alliam</span></div><h1>Train.<br/>Compete.<br/>Rise.</h1><p>Serious voice-first spelling for learners, schools, and tournaments.</p><div class="onboarding-dots">${steps.map((_,i)=>`<i class="${i===runtime.onboardingStep?'active':''}"></i>`).join("")}</div></aside><main class="onboarding-main"><section class="onboarding-form">${steps[runtime.onboardingStep]}<div class="form-actions"><button class="btn ${runtime.onboardingStep===0?'hidden':''}" data-action="onboard-back">Back</button><button class="btn btn-primary" data-action="onboard-next">${runtime.onboardingStep===steps.length-1?'Enter Alliam':'Continue'}</button></div><button class="btn btn-ghost" data-action="load-demo">Explore with a demo profile</button></section></main></div>`;
  }

  function renderShell(current,body){
    const p=accountIdentity();
    const mainNav=[["home","home","Home"],["train","dumbbell","Train"],["compete","swords","Compete"],["rankings","chart","Rankings"],["social","users","Friends & teams"]];
    const isHome=current==='home';
    return `<div class="app-shell ${isHome?'home-shell':'top-level-shell'} ${runtime.sidebarCollapsed&&!isHome?'sidebar-is-collapsed':''} ${runtime.mobileMenu&&!isHome?'mobile-menu-open':''}">
      ${isHome?'':`<button class="mobile-menu-toggle" data-action="toggle-mobile-menu" aria-label="Open menu">${icon('menu')}</button>
      <button class="mobile-menu-backdrop" data-action="toggle-mobile-menu" aria-label="Close menu"></button>
      <aside class="sidebar accepted-sidebar">
        <section class="sidebar-upper">
          <nav class="nav" aria-label="Main navigation">
            ${mainNav.map(([r,i,l])=>`<button class="${current===r?'active':''}" data-nav="${r}" title="${l}"><i>${icon(i)}</i><span>${l}</span></button>`).join("")}
          </nav>
        </section>
        <section class="sidebar-lower">
          <button class="sidebar-profile" data-action="toggle-profile-menu" title="${p.nickname}, ${p.grade}" aria-expanded="${runtime.profileMenu}">
            <span class="avatar">${p.avatar || initials(p.nickname)}</span>
            <span><strong>${p.nickname}</strong><small>${p.grade}</small></span>
          </button>
          ${runtime.profileMenu?`<div class="sidebar-profile-flyout"><button data-nav="profile">${icon('user')}<span>Profile</span></button>${state.profiles.length>1?`<button data-action="switch-profile">${icon('users')}<span>Switch learner</span></button>`:''}${isParentAccount()?`<button data-nav="parent">${icon('shield')}<span>Parent dashboard</span></button>`:''}<button data-nav="settings">${icon('settings')}<span>Settings</span></button><button data-action="sign-out">${icon('logout')}<span>Sign out</span></button></div>`:''}
          <button class="sidebar-settings" data-nav="settings" aria-label="Settings">${icon('settings')}<span>Settings</span></button>
        </section>
        <button class="sidebar-collapse" data-action="toggle-sidebar" aria-label="${runtime.sidebarCollapsed?'Expand':'Collapse'} sidebar" title="${runtime.sidebarCollapsed?'Expand':'Collapse'} sidebar">${icon('chevron')}</button>
      </aside>`}
      <div class="main-wrap route-${current} ${['train','compete'].includes(current)?'train-shell-main':''}">
        <header class="topbar"><button class="shell-brand" data-nav="home">Alliam</button><div class="top-actions"><button class="btn btn-icon shell-notifications" aria-label="Notifications" data-nav="notifications">${icon('bell')}</button></div></header>
        ${body}
      </div>
      ${isHome?'':`<nav class="mobile-nav">${mainNav.slice(0,5).map(([r,i,l])=>`<button class="${current===r?'active':''}" data-nav="${r}">${icon(i)}<span>${l}</span></button>`).join("")}</nav>`}
    </div>${runtime.modal?renderModal():''}`;
  }

  function renderRoute(current){
    if(current==="train-session") return renderTrainingSession();
    if(current==="train-result") return renderTrainingResult();
    if(current==="match") return renderMatch();
    if(current==="match-result") return renderMatchResult();
    const fn={home:renderHome,train:renderTrain,compete:renderCompete,rankings:renderRankings,social:renderSocial,profile:renderProfile,settings:renderSettings,parent:renderParent,school:renderSchool,admin:renderAdmin,notifications:renderNotifications}[current] || renderHome;
    return fn();
  }

  const pageHead=(eyebrow,title,copy,action="")=>`<div class="page-head"><div><div class="eyebrow">${eyebrow}</div><h2>${title}</h2>${copy?`<p>${copy}</p>`:''}</div>${action}</div>`;
  const actionCard=(ico,title,copy,action)=>`<button class="card action-card" data-action="${action}"><span class="card-icon">${icon(ico)}</span><h3>${title}</h3><p>${copy}</p></button>`;

  function renderHome(){ const p=profile(); return `<main class="page">${pageHead('Competitive spelling',`Welcome back, ${p.nickname}`,"Your next word is waiting.")}<section class="card hero-panel"><span class="eyebrow" style="color:#ffd5e4">CONTINUE TRAINING</span><h2>Foundation · Set ${state.trainingSessions+1}</h2><p>${state.reviewWords.length} review words ready · five-word session</p><div class="hero-actions"><button class="btn" data-action="quick-train">${icon('play')} Continue</button><button class="btn btn-ghost" data-nav="compete">Find a match</button></div></section><div class="grid grid-4" style="margin-top:18px"><div class="card stat"><small>Competition rating</small><div class="value">${state.rank}</div><span class="badge rank">Bronze I</span></div><div class="card stat"><small>Training sessions</small><div class="value">${state.trainingSessions}</div><span class="muted">Completed</span></div><div class="card stat"><small>Match record</small><div class="value">${state.matches.filter(m=>m.result==='Won').length}-${state.matches.filter(m=>m.result==='Lost').length}</div><span class="muted">Win–loss</span></div><div class="card stat"><small>Words to review</small><div class="value">${state.reviewWords.length}</div><button class="btn btn-ghost btn-sm" data-action="review-words">Practise</button></div></div><div class="section-head"><h3>Choose your next move</h3></div><div class="grid grid-3">${actionCard('dumbbell','Focused practice','Prepare with a structured word set.','quick-train')}${actionCard('swords','Quick match','Enter a casual 1v1 queue.','quick-match')}${actionCard('clock','Daily challenge','Five words. One attempt each.','daily')}</div><div class="grid grid-2"><section><div class="section-head"><h3>Recent activity</h3><button class="btn btn-ghost btn-sm" data-nav="profile">View all</button></div><div class="card">${recentActivity()}</div></section><section><div class="section-head"><h3>Upcoming</h3></div><div class="card"><div class="list-row"><span class="avatar">D</span><div class="list-main"><strong>District warm-up</strong><small>Saturday · 10:00 WAT</small></div><span class="badge">Practice</span></div><div class="list-row"><span class="avatar">1v1</span><div class="list-main"><strong>Challenge from Tobi</strong><small>Private match · Foundation</small></div><button class="btn btn-sm" data-action="accept-challenge">Accept</button></div></div></section></div></main>`; }
  function recentActivity(){ const items=state.matches.slice(0,3); if(!items.length) return `<div class="empty-state">${icon('flag')}<h3>No matches yet</h3><p>Your results will appear here.</p></div>`; return items.map(m=>`<div class="list-row"><span class="avatar">${initials(m.opponent)}</span><div class="list-main"><strong>${m.result} vs ${m.opponent}</strong><small>${m.mode} · ${m.score}</small></div><span class="badge ${m.result==='Won'?'good':''}">${m.rating>0?'+':''}${m.rating}</span></div>`).join(""); }

  function renderHome(){
    const p=profile();
    return `<main class="page home-page">
      ${pageHead('',`Welcome back, ${p.nickname}`,'')}
      <div class="section-head"><h3>Choose your next move</h3></div>
      <div class="grid grid-3 home-actions">
        ${actionCard('dumbbell','Focused practice','Prepare with a structured word set.','quick-train')}
        ${actionCard('swords','Quick match','Enter a casual 1v1 queue.','quick-match')}
        ${actionCard('clock','Daily challenge','Five words. One attempt each.','daily')}
      </div>
      <div class="grid grid-2 home-lower">
        <section>
          <div class="section-head"><h3>Recent activity</h3><button class="btn btn-ghost btn-sm" data-nav="profile">View all</button></div>
          <div class="card">${recentActivity()}</div>
        </section>
        <section>
          <div class="section-head"><h3>Upcoming</h3></div>
          <div class="card">
            <div class="list-row"><span class="avatar">D</span><div class="list-main"><strong>District warm-up</strong><small>Saturday · 10:00 WAT</small></div><span class="badge">Practice</span></div>
            <div class="list-row"><span class="avatar">1v1</span><div class="list-main"><strong>Challenge from Tobi</strong><small>Private match · Foundation</small></div><button class="btn btn-sm" data-action="accept-challenge">Accept</button></div>
          </div>
        </section>
      </div>
    </main>`;
  }

  function renderHome(){
    const p=profile(),invitations=runtime.live.invitations.filter(item=>item.status==='pending');
    const upcoming=[
      ...runtime.live.events.map(event=>`<div class="list-row"><span class="avatar">${initials(event.title)}</span><div class="list-main"><strong>${event.title}</strong><small>${event.startsAt||'Scheduled'} · ${event.type}</small></div><span class="badge">${event.status}</span></div>`),
      ...invitations.map(invitation=>`<div class="list-row"><span class="avatar">${initials(invitation.senderProfile?.nickname)}</span><div class="list-main"><strong>Challenge from ${invitation.senderProfile?.nickname||'a speller'}</strong><small>${invitation.mode}</small></div><button class="btn btn-sm" data-action="respond-invitation" data-invitation-id="${invitation.id}" data-accept="true">Accept</button></div>`)
    ].join('');
    return `<main class="page home-page">${pageHead('',`Welcome back, ${p.nickname}`,'')}<div class="section-head"><h3>Choose your next move</h3></div><div class="grid grid-3 home-actions">${actionCard('dumbbell','Focused practice','Prepare with a structured word set.','quick-train')}${actionCard('swords','Quick match','Enter a casual 1v1 queue.','quick-match')}${actionCard('clock','Daily challenge','Five words. One attempt each.','daily')}</div><div class="grid grid-2 home-lower"><section><div class="section-head"><h3>Recent activity</h3><button class="btn btn-ghost btn-sm" data-nav="profile">View all</button></div><div class="card">${recentActivity()}</div></section><section><div class="section-head"><h3>Upcoming</h3></div><div class="card">${upcoming||'<div class="empty-state"><h3>Nothing scheduled</h3><p>Invitations and events will appear here.</p></div>'}</div></section></div></main>`;
  }
  function renderHome(){
    const p=profile();
    const destinations=[
      ['train','dumbbell','Train','Build your spelling'],
      ['compete','swords','Compete','Enter the arena'],
      ['rankings','chart','Rankings','See your position'],
      ['social','users','Friends & teams','Spell together'],
      ['profile','user','Profile','Your progress'],
      ['settings','settings','Settings','Make it yours']
    ];
    return `<main class="home-menu-page">
      <section class="home-menu-intro">
        <span class="home-menu-kicker">Welcome back, ${String(p.nickname||'Speller').trim().split(/\s+/)[0]}</span>
        <h1>Where to?</h1>
      </section>
      <nav class="home-menu-grid" aria-label="Alliam destinations">
        ${destinations.map(([route,ico,title,copy])=>`<button class="home-menu-card" data-nav="${route}">
          <span class="home-menu-icon">${icon(ico)}</span>
          <strong>${title}</strong>
          <small>${copy}</small>
        </button>`).join('')}
      </nav>
    </main>`;
  }

  function renderTrain(){
    const s=runtime.trainingSetup;
    const requiresAudio=!['Word Flash','Missing Letters','Build the Word'].includes(s.mode);
    const modes=[
      ["Hear & Spell","train-icon-hear.png","Learn with pronunciation and letter guidance"],
      ["Listen & Spell","volume","Hear only, then spell from memory"],
      ["Word Flash","train-icon-flash.png","See briefly, then recall"],
      ["Timed Drill","train-icon-time.png","Build accuracy against the clock"],
      ["Missing Letters","edit","Complete only the hidden letters"],
      ["Pattern Drill","refresh","Master recurring spelling structures"],
      ["Similar Words","help","Separate commonly confused spellings"],
      ["Build the Word","database","Construct words from meaningful pieces"],
      ["Mock Bee","train-icon-bee.png","Practise with competition rules"],
      ["Survival Run","shield","Keep spelling while your lives remain"],
      ["Streak Challenge","chart","Protect your longest correct streak"],
      ["Recall Ladder","chart","Advance through mastery stages"],
      ["Daily Challenge","clock","One shared curated set every day"],
      ["Theme Challenge","flag","Practise a focused subject collection"],
      ["Reverse Spell","refresh","Hear the letters and identify the word"],
      ["Missed Words","train-icon-missed.png","Return to words you missed"]
    ];
    const config=trainingConfigFor(s.mode);
    return `<main class="train-experience train-select-experience">
      <div class="train-structural-lines" aria-hidden="true"></div>
      <section class="train-stage train-selection-stage">
        <div class="train-information train-selection-title"><h1>Choose your training</h1><p>Pick a mode and begin</p></div>
        <section class="train-mode-grid" aria-label="Training modes">
          ${modes.map(([name,asset,copy])=>`<button class="train-mode arena-card ${s.mode===name?'active':''}" data-training-mode="${name}" aria-pressed="${s.mode===name}"><span class="train-mode-icon">${asset.includes('.')?`<img src="assets/${asset}" alt="" aria-hidden="true">`:icon(asset)}</span><strong>${name}</strong><small>${copy}</small></button>`).join('')}
        </section>
        <div class="train-config-row">
          <section class="train-options train-config-card is-updated" aria-label="Session options">
            <header class="train-config-head"><span class="train-config-mark">${icon('settings')}</span><div><h3>Configure</h3><small>${s.mode}</small></div></header>
            <div class="train-config-fields">
              <div class="field"><label for="trainingLevel">${config.levelLabel}</label><select class="select" id="trainingLevel">${config.levels.map(x=>`<option ${s.level===x?'selected':''}>${x}</option>`).join('')}</select></div>
              <div class="field"><label for="trainingCount">${config.countLabel}</label><select class="select" id="trainingCount">${config.counts.map(x=>`<option value="${x}" ${Number(s.count)===x?'selected':''}>${x}</option>`).join('')}</select></div>
              <div class="field train-assistance"><label for="trainingAssistance">${config.optionLabel}</label><select class="select" id="trainingAssistance">${config.options.map(x=>`<option ${s.assistance===x?'selected':''}>${x}</option>`).join('')}</select></div>
            </div>
            <footer class="train-config-action"><button class="train-start" data-action="start-training"><span>Go</span></button>${requiresAudio&&runtime.audioStatus==='error'?`<small class="audio-load-error">${runtime.audioError}</small>`:''}</footer>
          </section>
        </div>
      </section>
    </main>`;
  }

  function shuffledWords(values){
    const result=[...values];
    for(let index=result.length-1;index>0;index--){
      let randomIndex;
      if(globalThis.crypto?.getRandomValues){
        const randomValue=new Uint32Array(1);
        crypto.getRandomValues(randomValue);
        randomIndex=randomValue[0]%(index+1);
      }else randomIndex=Math.floor(Math.random()*(index+1));
      [result[index],result[randomIndex]]=[result[randomIndex],result[index]];
    }
    return result;
  }

  function selectSessionWords(pool,count,{deterministic=false}={}){
    const selected=[];
    let batch=deterministic?[...pool]:shuffledWords(pool);
    if(!deterministic&&batch.length>1&&batch[0].word===runtime.lastSessionFirstWord){
      [batch[0],batch[1]]=[batch[1],batch[0]];
    }
    while(selected.length<count){
      if(!batch.length){
        batch=deterministic?[...pool]:shuffledWords(pool);
        if(batch.length>1&&selected.at(-1)?.word===batch[0].word){
          [batch[0],batch[1]]=[batch[1],batch[0]];
        }
      }
      selected.push(batch.shift());
    }
    runtime.lastSessionFirstWord=selected[0]?.word||null;
    return selected;
  }

  function createSession(source="training"){
    const setup=runtime.trainingSetup,library=allWords(); let pool=library.filter(w=>w.level===setup.level);
    if(setup.mode==="Missed Words") pool=library.filter(w=>state.reviewWords.includes(w.word));
    if(['Survival Run','Streak Challenge'].includes(setup.mode)){
      const levels=['Foundation','Builder','Championship'],start=Math.max(0,levels.indexOf(setup.level));
      const tiers=levels.slice(start).map(level=>shuffledWords(library.filter(word=>word.level===level)));
      const longest=Math.max(...tiers.map(tier=>tier.length));
      pool=Array.from({length:longest},(_,index)=>tiers.map(tier=>tier[index]).filter(Boolean)).flat();
    }
    if(setup.mode==='Pattern Drill'){
      const pattern=setup.assistance.replace(' / ','|').replace(/^-/,'');
      const focused=pool.filter(item=>new RegExp(pattern.replace('Silent letters','kn|wr|mb').replace('Double consonants','([a-z])\\1').replace('Latin roots','tion|ment|port').replace('Greek roots','ph|ch|graph'),'i').test(item.word));
      if(focused.length)pool=focused;
    }
    if(setup.mode==='Daily Challenge'){
      const day=Math.floor(Date.now()/86400000),offset=day%Math.max(1,pool.length);
      pool=[...pool.slice(offset),...pool.slice(0,offset)];
    }
    if(setup.mode==='Theme Challenge'){
      const offset=[...setup.assistance].reduce((sum,letter)=>sum+letter.charCodeAt(0),0)%Math.max(1,pool.length);
      pool=[...pool.slice(offset),...pool.slice(0,offset)];
    }
    if(!pool.length) pool=library.slice(0,5);
    const words=selectSessionWords(pool,Number(setup.count),{deterministic:setup.mode==='Daily Challenge'});
    runtime.session={source,words,index:0,position:0,attempt:[],correct:0,phase:setup.mode==='Hear & Spell'?'countdown':'ready',startedAt:Date.now(),results:[],secondsLeft:null,countdown:setup.mode==='Hear & Spell'?5:null,infoType:null,usedRequests:[],reflashes:0,animateBoxes:true,lives:setup.assistance==='Sudden death'?1:3,streak:0,bestStreak:0,ladderStage:0,pressure:Boolean(setup.pressure)};
    prepareModeWord(runtime.session);
  }

  function prepareModeWord(session){
    const mode=runtime.trainingSetup.mode,word=session.words[session.index].word;
    if(mode==='Missing Letters'){
      const option=runtime.trainingSetup.assistance;
      let indices=[];
      if(option==='One missing letter')indices=[Math.floor(word.length/2)];
      else if(option==='Vowels only')indices=[...word].map((letter,index)=>/[aeiou]/i.test(letter)?index:-1).filter(index=>index>=0);
      else if(option==='Prefixes')indices=[...Array(Math.min(3,word.length)).keys()];
      else if(option==='Suffixes')indices=[...Array(Math.min(3,word.length)).keys()].map(index=>word.length-1-index).reverse();
      else if(option==='Difficult letters only')indices=[...word].map((letter,index)=>/[cqxyzph]/i.test(letter)?index:-1).filter(index=>index>=0);
      if(!indices.length)indices=[1,Math.max(2,word.length-2)].filter((value,index,array)=>value<word.length&&array.indexOf(value)===index);
      session.missingIndices=indices;session.expectedAnswer=indices.map(index=>word[index]).join('');
    }else session.expectedAnswer=word;
  }

  function buildWordPieces(word,variant){
    let pieces;
    if(variant==='Syllable blocks')pieces=word.match(/[^aeiou]*[aeiou]+(?:[^aeiou](?![aeiou]))*/gi)||[word];
    else if(variant==='Prefix + root + suffix'){
      const edge=Math.max(1,Math.min(3,Math.floor(word.length/3)));
      pieces=[word.slice(0,edge),word.slice(edge,-edge),word.slice(-edge)].filter(Boolean);
    }else pieces=[...word];
    if(variant==='Distractor letters')pieces=[...pieces,'x','q'];
    return pieces.map((piece,index)=>({piece,index,rank:(piece.charCodeAt(0)||0)*17+index})).sort((a,b)=>b.rank-a.rank).map(item=>item.piece);
  }

  const trainingModeRules={
    'Hear & Spell':{ready:'Study the word, hear it pronounced and spelled, then try it yourself.',action:'Hear and begin'},
    'Listen & Spell':{ready:'Hear the pronunciation only, then spell the word from memory.',action:'Listen'},
    'Word Flash':{ready:'The word will flash on screen for three seconds. Memorise it before it disappears.',action:'Flash word'},
    'Timed Drill':{ready:'Hear the word once, then spell it before the 20-second clock expires.',action:'Start timer'},
    'Missing Letters':{ready:'Complete only the missing letters in the word.',action:'Begin'},
    'Pattern Drill':{ready:'Focus on the highlighted spelling pattern, then spell the complete word.',action:'Begin pattern'},
    'Similar Words':{ready:'Study the meaning carefully, then spell the intended word.',action:'Begin pair'},
    'Build the Word':{ready:'Construct the word from its spelling pieces.',action:'Build'},
    'Mock Bee':{ready:'Competition rules apply. The written word stays hidden; request information if needed.',action:'Announce word'},
    'Survival Run':{ready:'You have three lives. Keep spelling as difficulty rises.',action:'Start run'},
    'Streak Challenge':{ready:'Build the longest correct streak you can.',action:'Start streak'},
    'Recall Ladder':{ready:'Each correct answer moves the word to a harder recall stage.',action:'Start ladder'},
    'Daily Challenge':{ready:'Complete today’s shared word set with one attempt per word.',action:'Begin today'},
    'Theme Challenge':{ready:'Spell a set of words connected by one theme.',action:'Begin theme'},
    'Reverse Spell':{ready:'Listen to the letter sequence, then identify and spell the complete word.',action:'Hear letters'},
    'Missed Words':{ready:'Retry a word from your personal review list and clear it by spelling correctly.',action:'Review word'}
  };
  const trainingModeConfig={
    'Hear & Spell':{levelLabel:'Word level',levels:['Foundation','Builder','Championship'],countLabel:'Words',counts:[5,10,15],optionLabel:'Assistance',options:['Guided','Standard','Strict'],defaults:{level:'Foundation',count:5,assistance:'Guided'}},
    'Listen & Spell':{levelLabel:'Word level',levels:['Foundation','Builder','Championship'],countLabel:'Words',counts:[5,10,15],optionLabel:'Requests',options:['All requests','Three requests','No assistance'],defaults:{level:'Foundation',count:5,assistance:'All requests'}},
    'Word Flash':{levelLabel:'Word level',levels:['Foundation','Builder','Championship'],countLabel:'Words',counts:[5,10,15],optionLabel:'Flash time',options:['2 seconds','3 seconds','5 seconds'],defaults:{level:'Foundation',count:10,assistance:'3 seconds'}},
    'Timed Drill':{levelLabel:'Word level',levels:['Foundation','Builder','Championship'],countLabel:'Words',counts:[5,10,15],optionLabel:'Time per word',options:['10 seconds','20 seconds','30 seconds'],defaults:{level:'Builder',count:10,assistance:'20 seconds'}},
    'Missing Letters':{levelLabel:'Word level',levels:['Foundation','Builder','Championship'],countLabel:'Words',counts:[5,10,15],optionLabel:'Missing pattern',options:['One missing letter','Multiple missing letters','Vowels only','Difficult letters only','Prefixes','Suffixes'],defaults:{level:'Foundation',count:10,assistance:'Multiple missing letters'}},
    'Pattern Drill':{levelLabel:'Word level',levels:['Foundation','Builder','Championship'],countLabel:'Words',counts:[5,10,15],optionLabel:'Pattern',options:['-tion','-sion','-cian','ie / ei','Silent letters','Double consonants','Latin roots','Greek roots'],defaults:{level:'Builder',count:10,assistance:'-tion'}},
    'Similar Words':{levelLabel:'Word level',levels:['Builder','Championship'],countLabel:'Pairs',counts:[5,10,15],optionLabel:'Group',options:['Common pairs','Sound-alikes','Competition set'],defaults:{level:'Builder',count:5,assistance:'Common pairs'}},
    'Build the Word':{levelLabel:'Word level',levels:['Foundation','Builder','Championship'],countLabel:'Words',counts:[5,10,15],optionLabel:'Pieces',options:['Letter tiles','Syllable blocks','Prefix + root + suffix','Distractor letters'],defaults:{level:'Foundation',count:10,assistance:'Letter tiles'}},
    'Mock Bee':{levelLabel:'Division',levels:['Foundation','Builder','Championship'],countLabel:'Rounds',counts:[5,10,15],optionLabel:'Rules',options:['School','National','Championship'],defaults:{level:'Builder',count:5,assistance:'National'}},
    'Survival Run':{levelLabel:'Starting level',levels:['Foundation','Builder','Championship'],countLabel:'Word cap',counts:[10,20,30],optionLabel:'Lives',options:['Three lives','Sudden death'],defaults:{level:'Foundation',count:20,assistance:'Three lives'}},
    'Streak Challenge':{levelLabel:'Starting level',levels:['Foundation','Builder','Championship'],countLabel:'Target',counts:[10,20,30],optionLabel:'Assistance',options:['Standard','No assistance'],defaults:{level:'Foundation',count:20,assistance:'No assistance'}},
    'Recall Ladder':{levelLabel:'Starting level',levels:['Foundation','Builder','Championship'],countLabel:'Words',counts:[5,10,15],optionLabel:'Entry stage',options:['Hear & Spell','Listen & Spell','Word Flash'],defaults:{level:'Foundation',count:5,assistance:'Hear & Spell'}},
    'Daily Challenge':{levelLabel:'Division',levels:['Foundation','Builder','Championship'],countLabel:'Words',counts:[5,10],optionLabel:'Scoring',options:['Balanced','Accuracy','Speed'],defaults:{level:'Foundation',count:5,assistance:'Balanced'}},
    'Theme Challenge':{levelLabel:'Word level',levels:['Foundation','Builder','Championship'],countLabel:'Words',counts:[5,10,15],optionLabel:'Theme',options:['Animals','Space','Science','Geography','Food','Shakespeare','Medical terms'],defaults:{level:'Foundation',count:10,assistance:'Animals'}},
    'Reverse Spell':{levelLabel:'Word level',levels:['Foundation','Builder','Championship'],countLabel:'Words',counts:[5,10,15],optionLabel:'Letter pace',options:['Slow','Standard','Fast'],defaults:{level:'Builder',count:10,assistance:'Standard'}},
    'Missed Words':{levelLabel:'Review level',levels:['Foundation','Builder','Championship'],countLabel:'Words',counts:[5,10,15],optionLabel:'Assistance',options:['Guided','Standard','Strict'],defaults:{level:'Foundation',count:5,assistance:'Guided'}}
  };
  function trainingConfigFor(mode){return trainingModeConfig[mode]||trainingModeConfig['Hear & Spell'];}
  function selectTrainingMode(mode){
    const config=trainingConfigFor(mode),learnerLevel=state.settings.learnerLevel||'Foundation';
    const level=config.levels.includes(learnerLevel)?learnerLevel:config.levels[0];
    const count=learnerLevel==='Foundation'?config.counts[0]:config.counts[Math.min(1,config.counts.length-1)];
    let assistance=config.defaults.assistance;
    const levelAssistance={Foundation:'Guided',Builder:'Standard',Championship:'Strict'}[learnerLevel];
    if(config.options.includes(levelAssistance))assistance=levelAssistance;
    runtime.trainingSetup={mode,...config.defaults,level,count,assistance,pressure:false};
  }
  const firstExerciseDelay=mode=>['Word Flash','Timed Drill'].includes(mode)?2400:350;
  const nextExerciseDelay=mode=>mode==='Word Flash'?900:350;
  const effectiveStrict=()=>['Strict','No assistance','Sudden death'].includes(runtime.trainingSetup.assistance)||['Timed Drill','Mock Bee','Daily Challenge'].includes(runtime.trainingSetup.mode);
  function clearTrainingTimer(){if(runtime.trainingTimer){clearInterval(runtime.trainingTimer);runtime.trainingTimer=null;}}
  function startTrainingTimer(){
    clearTrainingTimer();const s=runtime.session;s.secondsLeft=parseInt(runtime.trainingSetup.assistance,10)||20;
    runtime.trainingTimer=setInterval(()=>{if(!runtime.session||s.phase!=='attempt'){clearTrainingTimer();return;}s.secondsLeft--;if(s.secondsLeft<=0){clearTrainingTimer();recordTrainingAttempt(false,s.attempt.join(''));toast('Time is up.');}else render();},1000);
  }

  function requestsForMode(mode){
    if(mode==='Hear & Spell')return [['refresh','Repeat','repeat'],['eye','Hold to flash','holdFlash']];
    if(mode==='Word Flash')return [['refresh','Reflash','reflash']];
    if(['Timed Drill','Survival Run','Streak Challenge','Daily Challenge','Reverse Spell'].includes(mode))return [];
    if(mode==='Mock Bee')return [['refresh','Repeat','repeat'],['help','Definition','definition'],['edit','Sentence','sentence'],['school','Origin','origin'],['info','Part of speech','partOfSpeech']];
    if(mode==='Missed Words')return [['refresh','Repeat','repeat'],['help','Definition','definition'],['edit','Sentence','sentence']];
    if(mode==='Listen & Spell')return [['refresh','Repeat','repeat'],['help','Definition','definition'],['edit','Sentence','sentence'],['school','Origin','origin'],['info','Part of speech','partOfSpeech']];
    return [['refresh','Repeat','repeat'],['help','Definition','definition'],['edit','Sentence','sentence'],['school','Origin','origin'],['info','Part of speech','partOfSpeech']];
  }
  function renderTrainingSession(){
    const s=runtime.session; if(!s){createSession();}
    const session=runtime.session, entry=session.words[session.index], mode=runtime.trainingSetup.mode;
    const shown=mode==='Hear & Spell'
      ? session.phase==='ready'||session.phase==='teaching'||session.holdFlash
      : mode==='Word Flash'&&session.phase==='teaching'
        ||mode==='Recall Ladder'&&((session.ladderStage===0&&(session.phase==='ready'||session.phase==='teaching'))||(session.ladderStage===2&&session.phase==='teaching'));
    const information=trainingInformation(entry,session);
    const isListening=session.phase==='attempt';
    const isTeaching=session.phase==='teaching';
    const requestButtons=requestsForMode(mode);
    const lettersPerRow=Math.min(entry.word.length,10),wraps=entry.word.length>10;
    if(session.animateBoxes) setTimeout(()=>{if(runtime.session===session)session.animateBoxes=false;},750);
    return `<main class="train-experience ${session.pressure?'pressure-chamber':''} ${session.secondsLeft!==null&&session.secondsLeft<=10?'pressure-urgent':''} ${mode==='Hear & Spell'&&session.phase==='countdown'?'hear-spell-intro-active':''}">
      <div class="train-structural-lines" aria-hidden="true"></div>
      <header class="train-header"><button class="work-exit" data-nav="train" aria-label="Back to training modes" title="Back to training modes">${icon('home')}</button><button class="train-session-settings" data-action="open-session-settings" aria-label="Session settings">${icon('settings')}</button></header>
      ${['Hear & Spell','Missed Words'].includes(mode)?`<nav class="train-word-navigation" aria-label="Session word navigation">
        <button data-action="previous-training-word" ${session.index===0?'disabled':''}><img src="assets/session-arrow-previous.svg" alt="" aria-hidden="true"><span>Previous</span></button>
        <button data-action="next-session-word" ${session.index===session.words.length-1?'disabled':''}><span>Next</span><img class="next" src="assets/session-arrow-next.svg" alt="" aria-hidden="true"></button>
      </nav>`:''}
      <section class="train-stage">
        <button class="train-back" data-action="exit-session">${icon('chevron')} <span>Back</span></button>
        ${mode==='Hear & Spell'&&session.phase==='countdown'?'':`<div class="train-information" aria-live="polite"><h1>${information.title}</h1><p>${information.body}</p></div>`}
        ${['Survival Run','Streak Challenge','Recall Ladder','Daily Challenge'].includes(mode)?`<div class="mode-progress" aria-label="Challenge progress">${mode==='Survival Run'?`<span>${icon('shield')} ${session.lives} ${session.lives===1?'life':'lives'}</span>`:''}${mode==='Streak Challenge'?`<span>${icon('chart')} ${session.streak} streak</span>`:''}${mode==='Recall Ladder'?`<span>${icon('chart')} Stage ${session.ladderStage+1} of 6</span>`:''}${mode==='Daily Challenge'?`<span>${icon('clock')} Daily set · ${session.index+1}/${session.words.length}</span>`:''}</div>`:''}
        ${session.secondsLeft!==null&&(mode==='Timed Drill'||session.pressure)?`<div class="training-clock ${session.secondsLeft<=5?'urgent':''}">${icon('clock')}<strong>${session.secondsLeft}</strong><span>seconds</span></div>`:''}
        <div class="train-letter-stage ${wraps?'wraps':''} ${session.phase==='countdown'?'has-countdown':''}">${session.phase==='countdown'
          ? mode==='Hear & Spell'
            ? `<div class="hear-spell-intro" aria-live="assertive"><h1>Listen carefully</h1><p>Study the word, hear it pronounced and spelled, then try it yourself</p><span>${session.countdown}</span><small>Starting in</small></div>`
            : `<div class="flash-countdown" aria-live="assertive"><span>${session.countdown}</span><small>${mode==='Word Flash'?'Focus':'Ready'}</small></div>`
          : ['Word Flash','Timed Drill'].includes(mode)&&session.phase==='ready'
            ? `<div class="flash-countdown is-ready"><span>${icon(mode==='Word Flash'?'eye':'clock')}</span><small>Get ready</small></div>`
            : `<div class="train-diamonds ${session.animateBoxes?'is-entering':''} ${mode==='Word Flash'&&isTeaching?'is-flashing':''} ${session.phase==='feedback'&&session.results.at(-1)?.correct?'is-success-payoff':''}" style="--letter-count:${entry.word.length};--letters-per-row:${lettersPerRow}">${renderTrainDiamonds(entry,session,shown)}</div>`}</div>
        ${mode==='Build the Word'&&session.phase==='attempt'?`<div class="word-piece-tray" aria-label="Word pieces">${buildWordPieces(entry.word,runtime.trainingSetup.assistance).map(piece=>`<button data-piece="${piece}" aria-label="Add ${piece}">${piece.toUpperCase()}</button>`).join('')}</div>`:''}
        <div class="train-state-control ${isTeaching?'is-speaking':''}">
          ${mode==='Word Flash'?'':`<div class="train-wave" aria-hidden="true">${[8,14,20,28,36,28,20,14,8].map(h=>`<i style="height:${h}px"></i>`).join('')}</div>`}
          ${session.phase==='feedback'
            ? `<button class="train-main-control" data-action="next-training-word" aria-label="${session.index===session.words.length-1?'View results':'Next word'}">${icon('chevron')}</button>`
            : isListening
              ? `<div class="training-entry-actions"><button class="icon-label-action quiet" data-action="undo-letter" ${session.attempt.length?'':'disabled'}>${icon('refresh')}<span>Undo</span></button><button class="alliam-cta" data-action="submit-attempt" ${session.attempt.length?'':'disabled'}><span>Submit</span></button>${services.speech.configured&&mode!=='Word Flash'?`<button class="icon-label-action quiet" data-action="speech-placeholder">${icon('mic')}<span>Speak</span></button>`:''}</div>`
              : mode==='Word Flash'||mode==='Timed Drill'||session.phase==='countdown'
                ? ''
                : `<button class="train-main-control" data-action="begin-training-mode" ${isTeaching?'disabled':''} aria-label="Start word">${icon(isTeaching?'volume':'play')}</button>`}
          <strong>${session.phase==='ready'?(mode==='Word Flash'||mode==='Timed Drill'?'Starting…':'Tap to start'):session.phase==='countdown'?'Get ready':isTeaching?(mode==='Word Flash'?'Memorise':'Listen carefully'):isListening?'Type the spelling, then submit':session.results.at(-1)?.correct?'Well done':'Try again'}</strong>
        </div>
        ${requestButtons.length?`<div class="train-requests ${mode==='Hear & Spell'?'hear-spell-aids':''}" aria-label="Word assistance">${requestButtons.map(([ico,label,type])=>{const unlimited=mode==='Hear & Spell',used=!unlimited&&(session.usedRequests||[]).includes(type),unavailable=session.phase!=='attempt'||used,active=session.infoType===type||(type==='holdFlash'&&session.holdFlash);const control=type==='reflash'?'data-action="reflash-word"':type==='holdFlash'?'data-hold-flash':`data-info="${type}"`;return `<button ${control} ${unavailable?'disabled':''} class="${used?'used':active?'active':''}" aria-label="${label}"><span>${icon(ico)}</span><small>${label}</small></button>`;}).join('')}</div>${mode==='Hear & Spell'?'':`<p class="train-request-count">${(session.usedRequests||[]).length} of ${requestButtons.length} ${requestButtons.length===1?'assist':'requests'} used</p>`}`:''}
      </section>
    </main>`;
  }

  function trainingInformation(entry,s){
    if(s.phase==='feedback') return s.results.at(-1)?.correct
      ? {title:'Correct',body:`${entry.word.toUpperCase()} — well done.`}
      : {title:'Review',body:`The correct spelling is ${entry.word.toUpperCase()}.`};
    const details={
      repeat:{title:'Repeat word',body:`Listen again. The word is ${entry.word}.`},
      definition:{title:'Definition',body:entry.definition},
      sentence:{title:'Example sentence',body:entry.sentence},
      origin:{title:'Language of origin',body:`The word comes from ${entry.origin}.`},
      partOfSpeech:{title:'Part of speech',body:`${entry.word} is a ${entry.part}.`}
    };
    if(details[s.infoType])return details[s.infoType];
    const mode=runtime.trainingSetup.mode;
    if(mode==='Word Flash'){
      if(s.phase==='countdown')return {title:'Eyes ready',body:'The word will appear after the countdown.'};
      if(s.phase==='teaching')return {title:'Memorise',body:`You have ${parseInt(runtime.trainingSetup.assistance,10)||3} seconds.`};
      if(s.phase==='attempt')return {title:'Recall the word',body:'Type the complete spelling from memory, then submit.'};
      return {title:'Word Flash',body:'Watch closely. The word will appear briefly, then disappear.'};
    }
    if(mode==='Timed Drill'){
      if(s.phase==='countdown')return {title:'Timed Drill',body:'The clock starts after the word is announced.'};
      if(s.phase==='attempt')return {title:'Beat the clock',body:'Type the spelling and submit before time expires.'};
      return {title:'Timed Drill',body:'Listen once, then spell the word against the clock.'};
    }
    if(mode==='Listen & Spell')return {title:'Listen & Spell',body:s.phase==='attempt'?'Spell the word you heard.':'Only the pronunciation will be played.'};
    if(mode==='Missing Letters')return {title:'Missing Letters',body:s.phase==='attempt'?'Enter the hidden letters from left to right.':'Study the visible spelling and complete its gaps.'};
    if(mode==='Pattern Drill')return {title:runtime.trainingSetup.assistance,body:s.phase==='attempt'?'Spell the complete word using the focus pattern.':'Listen for the recurring spelling structure.'};
    if(mode==='Similar Words')return {title:'Choose by meaning',body:s.phase==='attempt'?entry.definition:'Listen carefully—the meaning separates this word from its pair.'};
    if(mode==='Build the Word')return {title:'Build the Word',body:s.phase==='attempt'?`Construct ${entry.word.length} letters in the correct order.`:'Break the word into useful spelling pieces.'};
    if(mode==='Survival Run')return {title:'Survival Run',body:s.phase==='attempt'?`${s.lives} ${s.lives===1?'life':'lives'} remaining.`:'Three mistakes end the run.'};
    if(mode==='Streak Challenge')return {title:`Streak ${s.streak}`,body:s.phase==='attempt'?'Keep the run alive. No assistance.':`Best this session: ${s.bestStreak}.`};
    if(mode==='Recall Ladder')return {title:`Recall stage ${s.ladderStage+1}`,body:['Hear and study','Listen only','Flash recall','Delayed recall','Timed recall','Competition recall'][s.ladderStage]||'Competition recall'};
    if(mode==='Daily Challenge')return {title:'Daily Challenge',body:s.phase==='attempt'?'One attempt. Make it count.':'Today’s set is the same for every learner.'};
    if(mode==='Theme Challenge')return {title:runtime.trainingSetup.assistance,body:s.phase==='attempt'?'Spell the themed word.':`Today’s collection: ${runtime.trainingSetup.assistance}.`};
    if(mode==='Reverse Spell')return {title:'Name the word',body:s.phase==='attempt'?'Type the complete word represented by the letters you heard.':'Listen to the letter sequence.'};
    if(mode==='Mock Bee')return {title:'Mock Bee',body:s.phase==='attempt'?'Type your final spelling. Requests may be used once.':'The word stays hidden until the result.'};
    if(mode==='Missed Words')return {title:'Review',body:'Clear this word from your missed list by spelling it correctly.'};
    return {title:'Listen carefully',body:'Study the word, hear it pronounced and spelled, then try it yourself'};
  }

  function renderTrainDiamonds(entry,s,shown){
    const mode=runtime.trainingSetup.mode;
    return [...entry.word].map((letter,i)=>{
      const targetIndex=mode==='Missing Letters'?(s.missingIndices||[])[s.attempt.length]:s.attempt.length;
      let text=shown?letter.toUpperCase():'?';
      let classes='train-diamond';
      if(s.phase==='teaching'&&s.activeLetter===i) classes+=' active';
      if(s.phase==='attempt'){
        classes+=' waiting';
        if(i<s.attempt.length){classes+=' entered';text=effectiveStrict()?'•':s.attempt[i].toUpperCase();}
      }
      if(s.phase==='attempt'&&i<s.attempt.length)text=s.attempt[i].toUpperCase();
      if(s.phase==='attempt'&&i===targetIndex&&s.micListening)classes+=' listening-target';
      if(s.phase==='attempt'&&i===targetIndex&&s.micConnecting)classes+=' connecting-target';
      if(s.phase==='attempt'&&i===targetIndex&&s.micActivityId)classes+=' sound-active';
      if(s.phase==='attempt'&&(mode==='Missing Letters'?(s.missingIndices||[])[s.heardFeedback?.index]===i:s.heardFeedback?.index===i)){
        classes+=` heard-pulse ${s.heardFeedback.correct?'heard-correct':'heard-incorrect'}`;
        if(!s.heardFeedback.correct)text=s.heardFeedback.letter.toUpperCase();
      }
      if(mode==='Missing Letters'&&s.phase!=='feedback'){
        const answerIndex=(s.missingIndices||[]).indexOf(i);
        classes+=answerIndex>=0?' missing-slot':' given-letter';
        text=answerIndex<0?letter.toUpperCase():(answerIndex<s.attempt.length?s.attempt[answerIndex].toUpperCase():'?');
        if(answerIndex===s.heardFeedback?.index&&!s.heardFeedback.correct)text=s.heardFeedback.letter.toUpperCase();
      }
      if(s.phase==='feedback'){
        const answer=s.results.at(-1)?.attempt||'';
        text=letter.toUpperCase();
        if(mode==='Missing Letters'){
          const answerIndex=(s.missingIndices||[]).indexOf(i);
          classes+=answerIndex<0||answer[answerIndex]===letter?' correct':' incorrect';
        }else classes+=answer[i]===letter?' correct':' incorrect';
      }
      return `<div class="${classes}" data-rive-slot="letter-box" data-letter-index="${i}" style="--letter-index:${i}"><div class="train-diamond-surface" aria-hidden="true"></div><span>${text}</span></div>`;
    }).join('');
  }

  function sessionPrompt(entry,s){
    const mode=runtime.trainingSetup.mode;
    if(s.phase==='ready') return trainingModeRules[mode].ready;
    if(s.phase==='teaching') return mode==='Word Flash'?'Look closely. The word is about to disappear.':mode==='Hear & Spell'?'Listen as each letter is called.':entry.definition;
    if(s.phase==='attempt') return mode==='Timed Drill'?'Enter the complete word before time runs out.':mode==='Mock Bee'?'Spell the complete word. You may request the permitted information.':effectiveStrict()?'Spell the complete word. Results appear at the end.':'Spell one letter at a time.';
    const r=s.results.at(-1); return r?.correct?`${entry.word.toUpperCase()} — well done.`:`The correct spelling is ${entry.word.toUpperCase()}.`;
  }
  function renderLetterBoxes(entry,s,shown){
    return `<div class="letter-row">${[...entry.word].map((letter,i)=>{ let cls="letter-box"; let text=shown?letter:""; if(s.phase==='attempt'){ cls+=" empty"; if(i<s.attempt.length){cls="letter-box entered";text=runtime.trainingSetup.assistance==='Strict'?'•':s.attempt[i];} } if(s.phase==='feedback'){const answer=s.results.at(-1)?.attempt||"";text=letter;cls+=answer[i]===letter?' correct':' incorrect';} if(s.activeLetter===i)cls+=' active'; return `<div class="${cls}">${text}</div>`;}).join("")}</div>`;
  }
  function renderSessionControls(entry,s){
    if(s.phase==='feedback') return `<div class="game-controls"><button class="btn btn-primary" data-action="next-training-word">${s.index===s.words.length-1?'View results':'Next word'} ${icon('chevron')}</button></div>`;
    const rule=trainingModeRules[runtime.trainingSetup.mode];
    return `<div class="game-controls">${runtime.trainingSetup.mode!=='Word Flash'?`<button class="btn btn-icon" aria-label="Repeat" data-action="play-word">${icon('refresh')}</button>`:''}<button class="btn btn-primary" data-action="begin-training-mode">${icon('play')} ${rule.action}</button><button class="btn btn-icon" aria-label="Skip" data-action="skip-training">${icon('skip')}</button></div>`;
  }
  function renderAttemptControls(entry,s){
    const strict=effectiveStrict();
    return `<div class="word-tools">${runtime.trainingSetup.mode==='Mock Bee'?[['refresh','Repeat','repeat'],['help','Definition','definition'],['edit','Sentence','sentence'],['school','Origin','origin'],['info','Part of speech','partOfSpeech']].map(([i,l,a])=>`<button class="btn btn-sm" data-info="${a}">${icon(i)}<span>${l}</span></button>`).join(''):''}</div><div class="keyboard">${"abcdefghijklmnopqrstuvwxyz".split("").map(l=>`<button data-letter="${l}">${l.toUpperCase()}</button>`).join("")}</div><div class="game-controls"><button class="btn btn-icon" data-action="undo-letter" aria-label="Remove last letter">${icon('refresh')}</button>${strict?`<button class="btn btn-primary" data-action="submit-attempt">Submit attempt</button>`:`<button class="btn btn-icon listen" data-action="speech-placeholder" aria-label="Speak">${icon('mic')}</button>`}</div>`;
  }

  async function beginTrainingExercise(){
    const s=runtime.session,e=s.words[s.index],mode=runtime.trainingSetup.mode;
    if(!['Word Flash','Missing Letters','Build the Word'].includes(mode)&&!await ensureRecordedAudio())return;
    clearTrainingTimer();s.attempt=[];s.holdFlash=false;s.micConnecting=false;s.micListening=false;s.micActivityId=null;s.heardFeedback=null;s.pendingHeardLetters=[];
    if(mode==='Hear & Spell'&&!s.introComplete){
      s.phase='countdown';
      for(let count=5;count>0;count--){
        if(runtime.session!==s)return;
        s.countdown=count;render();
        await services.delay(1000);
      }
      if(runtime.session!==s)return;
      s.introComplete=true;s.countdown=null;
    }
    s.phase='teaching';render();
    if(mode==='Recall Ladder'&&s.ladderStage===2){
      s.phase='countdown';
      for(let count=3;count>0;count--){if(runtime.session!==s)return;s.countdown=count;render();await services.delay(800);}
      s.phase='teaching';s.countdown=null;s.animateBoxes=true;render();await services.delay(2000);
    }else if(mode==='Word Flash'){
      s.phase='countdown';
      for(let count=3;count>0;count--){
        if(runtime.session!==s)return;
        s.countdown=count;render();
        await services.delay(800);
      }
      if(runtime.session!==s)return;
      s.phase='teaching';s.countdown=null;s.animateBoxes=true;render();
      await services.delay((parseInt(runtime.trainingSetup.assistance,10)||3)*1000);
    }else if(mode==='Hear & Spell'||(mode==='Recall Ladder'&&s.ladderStage===0)){
      if(mode==='Hear & Spell')await services.delay(2000);
      await services.audio.playWord(e);
      if(mode==='Hear & Spell'){
        await services.delay(3000);
        await services.audio.playWord(e);
      }
      await services.delay(650);
      await services.audio.spell(e.word,i=>{s.activeLetter=i;render();});
    }else if(mode==='Reverse Spell'){
      await services.audio.spell(e.word,i=>{s.activeLetter=i;render();});
    }else if(['Missing Letters','Build the Word'].includes(mode)){
      await services.delay(900);
    }else if(mode==='Missed Words'){
      await services.audio.playWord(e);
      await new Promise(resolve=>setTimeout(resolve,900));
    }else{
      await services.audio.playWord(e);
      if(mode==='Recall Ladder'&&s.ladderStage===3)await services.delay(2500);
    }
    if(runtime.session!==s)return;
    s.phase='attempt';s.activeLetter=-1;s.animateBoxes=true;render();
    if(mode==='Timed Drill')startTrainingTimer();
    else if(mode==='Recall Ladder'&&s.ladderStage>=4){const original=runtime.trainingSetup.assistance;runtime.trainingSetup.assistance=s.ladderStage===4?'20 seconds':'12 seconds';startTrainingTimer();runtime.trainingSetup.assistance=original;}
    else if(s.pressure){const original=runtime.trainingSetup.assistance;runtime.trainingSetup.assistance='30 seconds';startTrainingTimer();runtime.trainingSetup.assistance=original;}
  }

  function renderTrainingResult(){ const s=runtime.session; if(!s)return renderTrain(); const accuracy=Math.round((s.correct/s.words.length)*100); return `<main class="game-page"><section class="game-stage"><div class="result-mark">${icon('check')}</div><div class="eyebrow">SESSION COMPLETE</div><h2>${accuracy}% accuracy</h2><p class="prompt">${s.correct} of ${s.words.length} words correct · ${Math.max(1,Math.round((Date.now()-s.startedAt)/60000))} min</p><div class="grid grid-3" style="margin:30px 0"><div class="card stat"><small>Correct</small><div class="value">${s.correct}</div></div><div class="card stat"><small>Points</small><div class="value">+${s.correct*10}</div></div><div class="card stat"><small>Review</small><div class="value">${s.words.length-s.correct}</div></div></div><div class="game-controls"><button class="btn" data-nav="train">New session</button><button class="btn btn-primary" data-action="finish-training">Return home</button></div></section></main>`; }

  function renderCompeteLegacy(){
    const arenas=[['swords','Casual','1v1','casual-match'],['trophy','Ranked','Rating','ranked-match'],['users','Private','Room code','private-room'],['shield','Teams','6v6','team-match'],['school','Schools','Fixture','school-match'],['flag','Tournament','Bracket','tournament']];
    return `<main class="page compete-page">${pageHead('Compete','Choose an arena','')}
      <section class="arena-grid">${arenas.map(([ico,title,label,action])=>`<button class="arena-card" data-action="${action}"><span>${icon(ico)}</span><strong>${title}</strong><small>${label}</small></button>`).join('')}</section>
      <section class="invite-panel card"><div class="panel-title"><span>${icon('inbox')}</span><strong>Invitation</strong><small>1</small></div><div class="list-row"><span class="avatar">TA</span><div class="list-main"><strong>Tobi A.</strong><small>Foundation · 1v1</small></div><button class="icon-label-action" data-action="accept-challenge">${icon('check')}<span>Accept</span></button><button class="icon-label-action quiet">${icon('x')}<span>Decline</span></button></div></section>
    </main>`;
  }

  async function beginMatch(mode="Casual 1v1"){
    if(!services.firebase.user||services.firebase.user.isAnonymous){toast('Sign in to enter a live match.');navigate('auth');return;}
    runtime.competition={mode,opponent:'Finding opponent…',round:1,totalRounds:5,playerScore:0,opponentScore:0,turn:'player',phase:'queue',word:allWords()[0],attempt:[],startedAt:Date.now(),seconds:60};
    navigate('match');render();
    try{
      const result=await services.firebase.joinMatchQueue(mode);
      if(result.matchId)subscribeToMatch(result.matchId);
      else if(result.status==='retry')setTimeout(()=>beginMatch(mode),500);
      else toast('Searching for another speller…');
    }catch(error){runtime.competition=null;toast(error.message);navigate('compete');}
  }
  function subscribeToMatch(matchId){
    runtime.matchUnsubscribe?.();
    runtime.matchUnsubscribe=services.firebase.subscribeMatch(matchId,syncLiveMatch);
  }
  function syncLiveMatch(match){
    if(!match)return;
    const uid=services.firebase.user?.uid;
    const opponentUid=match.players.find(id=>id!==uid);
    const opponentProfile=match.playerProfiles?.[opponentUid]||{};
    const word=allWords().find(entry=>entry.word===match.wordIds[match.currentRound])||allWords()[0];
    const mine=match.submissions?.[`${match.currentRound}_${uid}`];
    const theirs=match.submissions?.[`${match.currentRound}_${opponentUid}`];
    runtime.competition={
      ...(runtime.competition||{}),matchId:match.id,mode:match.mode,
      opponent:opponentProfile.nickname||opponentProfile.displayName||'Opponent',opponentUid,
      round:match.currentRound+1,totalRounds:match.totalRounds,
      playerScore:match.scores?.[uid]||0,opponentScore:match.scores?.[opponentUid]||0,
      word,attempt:runtime.competition?.word?.word===word.word?(runtime.competition.attempt||[]):[],
      startedAt:runtime.competition?.startedAt||Date.now(),seconds:60,turn:'player',
      phase:match.status==='completed'?'complete':(mine&&!theirs?'waiting':'playing'),
      lastCorrect:mine?.correct,serverStatus:match.status,
      completionReason:match.completionReason||null,forfeitedBy:match.forfeitedBy||null,winnerUid:match.winnerUid||null
    };
    if(match.status==='completed')navigate('match-result');else navigate('match');
    render();
  }
  function renderCompetitionDiamonds(entry,m){
    return [...entry.word].map((letter,i)=>{const entered=i<m.attempt.length,heard=m.heardFeedback?.index===i;return `<div class="train-diamond ${entered?'entered':'waiting'} ${heard?`heard-pulse ${m.heardFeedback.correct?'heard-correct':'heard-incorrect'}`:''}" style="--letter-index:${i}"><div class="train-diamond-surface" aria-hidden="true"></div><span>${entered?m.attempt[i].toUpperCase():'?'}</span></div>`;}).join('');
  }
  function renderMatchLegacy(){ const m=runtime.competition;if(!m)return renderCompete();
    if(m.phase==='lobby')return `<main class="competition-lobby"><section class="lobby-card"><span class="lobby-mark">${icon('swords')}</span><small>${m.mode}</small><h1>Ready?</h1><div class="versus-row"><div><span class="avatar">${initials(profile().nickname)}</span><strong>${profile().nickname}</strong><small>${state.rank}</small></div><b>VS</b><div><span class="avatar">${initials(m.opponent)}</span><strong>${m.opponent}</strong><small>${state.rank+34}</small></div></div><div class="lobby-checks"><span>${icon('volume')} Sound</span><span>${icon('mic')} Microphone</span></div><div class="game-controls"><button class="icon-label-action quiet" data-nav="compete">${icon('x')}<span>Leave</span></button><button class="alliam-cta" data-action="start-match">Start ${icon('chevron')}</button></div></section></main>`;
    if(m.phase==='feedback')return renderMatchFeedback(m);
    const entry=m.word,lettersPerRow=Math.min(entry.word.length,10); return `<main class="train-experience competition-experience"><div class="train-structural-lines" aria-hidden="true"></div><header class="train-header"><button class="train-logo" data-nav="home">All<span>iam</span></button><div class="competition-round">Round ${m.round}/${m.totalRounds}</div></header><section class="train-stage"><button class="train-back" data-action="leave-match">${icon('chevron')}<span>Leave</span></button><div class="competition-hud"><div><span class="avatar">${initials(profile().nickname)}</span><strong>${m.playerScore}</strong></div><span class="competition-timer">${icon('clock')} 00:${String(m.seconds).padStart(2,'0')}</span><div><strong>${m.opponentScore}</strong><span class="avatar">${initials(m.opponent)}</span></div></div><div class="train-information"><h1>${m.turn==='player'?'Your word':`${m.opponent}'s turn`}</h1><p>${m.turn==='player'?'Listen, then spell':'Waiting for attempt'}</p></div>${m.turn==='player'?`<div class="train-letter-stage"><div class="train-diamonds" style="--letter-count:${entry.word.length};--letters-per-row:${lettersPerRow}">${renderCompetitionDiamonds(entry,m)}</div></div><div class="competition-main-control"><button class="train-main-control listening" data-action="speech-placeholder" aria-label="Listening">${icon('mic')}</button><strong>Listening</strong></div><div class="train-requests">${[['refresh','Repeat','repeat'],['help','Definition','definition'],['edit','Sentence','sentence'],['school','Origin','origin']].map(([i,l,a])=>`<button data-match-info="${a}"><span>${icon(i)}</span><small>${l}</small></button>`).join('')}</div><div class="competition-submit"><button class="icon-label-action quiet" data-action="undo-match-letter">${icon('refresh')}<span>Undo</span></button><button class="alliam-cta" data-action="submit-match">Submit ${icon('chevron')}</button></div>`:`<div class="opponent-wait">${icon('volume')}<strong>Opponent spelling</strong><div class="progress"><span style="width:68%"></span></div></div>`}</section></main>`; }
  function renderMatchFeedbackLegacy(m){ const correct=m.lastCorrect; return `<main class="game-page"><section class="game-stage"><div class="result-mark ${correct?'':'fail'}">${icon(correct?'check':'x')}</div><div class="eyebrow">ROUND ${m.round}</div><h2>${correct?'Correct':'Incorrect'}</h2><p class="prompt">The word was ${m.word.word.toUpperCase()}.</p><div class="opponent-strip" style="max-width:600px;margin:28px auto"><strong>${profile().nickname}</strong><strong>${m.playerScore} — ${m.opponentScore}</strong><strong>${m.opponent}</strong></div><button class="btn btn-primary" data-action="next-match-round">${m.round===m.totalRounds?'View match result':'Next round'}</button></section></main>`; }
  function renderMatchResultLegacy(){ const m=runtime.competition;if(!m)return renderCompete(); const won=m.playerScore>=m.opponentScore; const rating=won?18:-11; return `<main class="game-page"><section class="game-stage"><div class="result-mark ${won?'':'fail'}">${icon(won?'trophy':'flag')}</div><div class="eyebrow">MATCH COMPLETE</div><h2>${won?'Victory':'Match complete'}</h2><p class="prompt">${profile().nickname} ${m.playerScore} — ${m.opponentScore} ${m.opponent}</p><div class="grid grid-3" style="margin:30px 0"><div class="card stat"><small>Rating</small><div class="value">${rating>0?'+':''}${rating}</div></div><div class="card stat"><small>Rounds won</small><div class="value">${m.playerScore}</div></div><div class="card stat"><small>Time</small><div class="value">${Math.max(1,Math.round((Date.now()-m.startedAt)/60000))}m</div></div></div><div class="game-controls"><button class="btn" data-action="rematch">Rematch</button><button class="btn btn-primary" data-action="close-match-result">Return home</button></div></section></main>`; }

  function competitionFrame(content,className='competition-experience'){
    return `<main class="train-experience ${className}"><div class="train-structural-lines" aria-hidden="true"></div><header class="train-header"><button class="train-logo" data-nav="home">All<span>iam</span></button></header><section class="train-stage competition-stage">${content}</section></main>${runtime.modal?renderModal():''}`;
  }
  function renderCompete(){
    const arenas=[['swords','Casual','1v1','casual-match'],['trophy','Ranked','Rating','ranked-match'],['users','Private','Room code','private-room'],['shield','Teams','6v6','team-match'],['school','Schools','Fixture','school-match'],['flag','Tournament','Bracket','tournament']];
    return `<main class="train-experience competition-select-experience"><div class="train-structural-lines" aria-hidden="true"></div><section class="train-stage competition-stage"><div class="train-information competition-select-title"><h1>Choose an arena</h1><p>Pick a format and begin</p></div><section class="arena-grid">${arenas.map(([ico,title,label,action])=>`<button class="arena-card" data-action="${action}"><span>${icon(ico)}</span><strong>${title}</strong><small>${label}</small></button>`).join('')}</section><section class="invite-panel card"><div class="panel-title"><span>${icon('inbox')}</span><strong>Invitation</strong><small>1</small></div><div class="list-row"><span class="avatar">TA</span><div class="list-main"><strong>Tobi A.</strong><small>Foundation · 1v1</small></div><button class="icon-label-action" data-action="accept-challenge">${icon('check')}<span>Accept</span></button><button class="icon-label-action quiet">${icon('x')}<span>Decline</span></button></div></section></section></main>`;
  }
  function renderCompete(){
    const arenas=[['swords','Casual','1v1','casual-match'],['trophy','Ranked','Rating','ranked-match'],['users','Private','Room code','private-room'],['shield','Teams','6v6','team-match'],['school','Schools','Fixture','school-match'],['flag','Tournament','Bracket','tournament']];
    const invitations=runtime.live.invitations.filter(item=>item.status==='pending');
    const rows=invitations.map(invitation=>`<div class="list-row"><span class="avatar">${initials(invitation.senderProfile?.nickname)}</span><div class="list-main"><strong>${invitation.senderProfile?.nickname||'Speller'}</strong><small>${invitation.mode}</small></div><button class="icon-label-action" data-action="respond-invitation" data-invitation-id="${invitation.id}" data-accept="true">${icon('check')}<span>Accept</span></button><button class="icon-label-action quiet" data-action="respond-invitation" data-invitation-id="${invitation.id}">${icon('x')}<span>Decline</span></button></div>`).join('');
    return `<main class="train-experience competition-select-experience"><div class="train-structural-lines" aria-hidden="true"></div><section class="train-stage competition-stage"><div class="train-information competition-select-title"><h1>Choose an arena</h1><p>Pick a format and begin</p></div><section class="arena-grid">${arenas.map(([ico,title,label,action])=>`<button class="arena-card" data-action="${action}"><span>${icon(ico)}</span><strong>${title}</strong><small>${label}</small></button>`).join('')}</section><section class="invite-panel card"><div class="panel-title"><span>${icon('inbox')}</span><strong>Invitations</strong><small>${invitations.length}</small></div>${rows||'<p class="muted">No pending invitations.</p>'}</section></section></main>`;
  }
  function renderMatch(){
    const m=runtime.competition;if(!m)return renderCompete();
    if(m.phase==='queue')return competitionFrame(`<section class="lobby-card"><span class="lobby-mark">${icon('search')}</span><small>${m.mode}</small><h1>Finding a speller</h1><p class="prompt">Keep this screen open. Your match begins when another player joins.</p><button class="icon-label-action quiet" data-action="leave-match">${icon('x')}<span>Cancel</span></button></section>`);
    if(m.phase==='lobby')return competitionFrame(`<section class="lobby-card"><span class="lobby-mark">${icon('swords')}</span><small>${m.mode}</small><h1>Ready?</h1><div class="versus-row"><div><span class="avatar">${initials(profile().nickname)}</span><strong>${profile().nickname}</strong><small>${state.rank}</small></div><b>VS</b><div><span class="avatar">${initials(m.opponent)}</span><strong>${m.opponent}</strong><small>${state.rank+34}</small></div></div><div class="lobby-checks"><span>${icon('volume')} Sound</span><span>${icon('mic')} Microphone</span></div><div class="game-controls"><button class="icon-label-action quiet" data-nav="compete">${icon('x')}<span>Leave</span></button><button class="alliam-cta" data-action="start-match">Start ${icon('chevron')}</button></div></section>`);
    if(m.phase==='feedback')return renderMatchFeedback(m);
    const entry=m.word,lettersPerRow=Math.min(entry.word.length,10);
    return competitionFrame(`<button class="train-back" data-action="leave-match">${icon('chevron')}<span>Leave</span></button><div class="competition-round">Round ${m.round}/${m.totalRounds}</div><div class="competition-hud"><div><span class="avatar">${initials(profile().nickname)}</span><strong>${m.playerScore}</strong></div><span class="competition-timer">${icon('clock')} 00:${String(m.seconds).padStart(2,'0')}</span><div><strong>${m.opponentScore}</strong><span class="avatar">${initials(m.opponent)}</span></div></div><div class="train-information"><h1>${m.turn==='player'?'Your word':`${m.opponent}'s turn`}</h1><p>${m.turn==='player'?'Listen, then spell':'Waiting for attempt'}</p></div>${m.turn==='player'?`<div class="train-letter-stage"><div class="train-diamonds" style="--letter-count:${entry.word.length};--letters-per-row:${lettersPerRow}">${renderCompetitionDiamonds(entry,m)}</div></div><div class="competition-main-control"><button class="train-main-control listening" data-action="speech-placeholder" aria-label="Listening">${icon('mic')}</button><strong>Listening</strong></div><div class="train-requests">${[['refresh','Repeat','repeat'],['help','Definition','definition'],['edit','Sentence','sentence'],['school','Origin','origin']].map(([i,l,a])=>`<button data-match-info="${a}"><span>${icon(i)}</span><small>${l}</small></button>`).join('')}</div><div class="competition-submit"><button class="icon-label-action quiet" data-action="undo-match-letter">${icon('refresh')}<span>Undo</span></button><button class="alliam-cta" data-action="submit-match">Submit ${icon('chevron')}</button></div>`:`<div class="opponent-wait">${icon('volume')}<strong>Opponent spelling</strong><div class="progress"><span style="width:68%"></span></div></div>`}`);
  }
  function renderMatchFeedback(m){const correct=m.lastCorrect;return competitionFrame(`<section class="game-stage"><div class="result-mark ${correct?'':'fail'}">${icon(correct?'check':'x')}</div><h2>${correct?'Correct':'Incorrect'}</h2><p class="prompt">The word was ${m.word.word.toUpperCase()}.</p><div class="opponent-strip"><strong>${profile().nickname}</strong><strong>${m.playerScore} — ${m.opponentScore}</strong><strong>${m.opponent}</strong></div><button class="alliam-cta" data-action="next-match-round">${m.round===m.totalRounds?'View result':'Next round'} ${icon('chevron')}</button></section>`);}
  function renderMatchResult(){const m=runtime.competition;if(!m)return renderCompete();const uid=services.firebase.user?.uid,isForfeit=m.completionReason==='forfeit',won=isForfeit?m.winnerUid===uid:m.playerScore>=m.opponentScore,rating=won?16:-16;const heading=isForfeit?(won?'Opponent forfeited':'Match forfeited'):(won?'Victory':'Match complete');const summary=isForfeit?(won?`${m.opponent} left the active match. You receive the win.`:'You left the active match and forfeited the result.'):`${profile().nickname} ${m.playerScore} — ${m.opponentScore} ${m.opponent}`;return competitionFrame(`<section class="game-stage"><div class="result-mark ${won?'':'fail'}">${icon(won?'trophy':'flag')}</div><h2>${heading}</h2><p class="prompt">${summary}</p><div class="grid grid-3 result-stats"><div class="card stat"><small>Rating</small><div class="value">${rating>0?'+':''}${rating}</div></div><div class="card stat"><small>Result</small><div class="value">${isForfeit?'Forfeit':m.playerScore}</div></div><div class="card stat"><small>Time</small><div class="value">${Math.max(1,Math.round((Date.now()-m.startedAt)/60000))}m</div></div></div><div class="game-controls">${isForfeit?'':`<button class="icon-label-action quiet" data-action="rematch">${icon('refresh')}<span>Rematch</span></button>`}<button class="alliam-cta" data-action="close-match-result">Done ${icon('chevron')}</button></div></section>`);}

  function renderRankings(){ const me=profile(); const rows=[...seedLeaderboard,[me.nickname,me.country,state.rank,state.matches.length]].sort((a,b)=>b[2]-a[2]); return `<main class="page">${pageHead('Competitive standings','Rankings','Compare performance across regions, grades, schools, and seasons.')}<div class="tabs">${['Global','Nigeria','State','School','Grade','Friends'].map((x,i)=>`<button class="${i===0?'active':''}" data-rank-tab="${x}">${x}</button>`).join('')}</div><div class="grid grid-3"><div class="card stat"><small>Your rating</small><div class="value">${state.rank}</div><span class="badge rank">Bronze I</span></div><div class="card stat"><small>Global position</small><div class="value">#${Math.max(8,2200-state.rank)}</div><span class="muted">Current season</span></div><div class="card stat"><small>Season ends</small><div class="value">24d</div><span class="muted">Placement active</span></div></div><div class="card table-wrap" style="margin-top:18px"><table class="table"><thead><tr><th>Rank</th><th>Speller</th><th>Region</th><th class="right">Rating</th><th class="right">Matches</th></tr></thead><tbody>${rows.map((r,i)=>`<tr class="${r[0]===me.nickname?'me':''}"><td><strong>${i+1}</strong></td><td>${r[0]} ${r[0]===me.nickname?'<span class="badge">You</span>':''}</td><td>${r[1]}</td><td class="right"><strong>${r[2]}</strong></td><td class="right">${r[3]}</td></tr>`).join('')}</tbody></table></div></main>`; }

  function renderSocial(){ return `<main class="page">${pageHead('Controlled network','Friends & teams','Challenge known spellers, represent a team, and keep student interaction safe.',`<button class="btn btn-primary" data-action="add-friend">${icon('plus')} Add friend</button>`)}<div class="tabs"><button class="active">Friends</button><button>Teams</button><button>Invites</button></div><div class="grid grid-2"><section><div class="section-head"><h3>Friends</h3><span class="badge">${state.friends.length}</span></div><div class="card">${state.friends.map(f=>`<div class="list-row"><span class="avatar">${initials(f.name)}</span><div class="list-main"><strong>${f.name}</strong><small>Rating ${f.rank} · ${f.status}</small></div><button class="btn btn-sm" data-action="challenge-friend" data-name="${f.name}">Challenge</button></div>`).join('')}</div></section><section><div class="section-head"><h3>Your teams</h3><button class="btn btn-ghost btn-sm" data-action="create-team">Create</button></div><div class="card">${state.teams.map(t=>`<div class="list-row"><span class="avatar">${initials(t.name)}</span><div class="list-main"><strong>${t.name}</strong><small>${t.school} · ${t.members} members</small></div><span class="badge rank">#${t.rank}</span></div>`).join('')}</div></section></div><div class="section-head"><h3>Safety</h3></div><div class="card"><div class="grid grid-3"><div><strong>No open messaging</strong><p>Student accounts use invitations and preset reactions only.</p></div><div><strong>Private identity</strong><p>Public profiles show competition nicknames and safe statistics.</p></div><div><strong>Report and block</strong><p>Every match and profile includes safety controls.</p></div></div></div></main>`; }

  function learnerJourney(p){
    const own=p.journey||{};
    const isActive=p.id===state.activeProfileId;
    const sessions=own.sessions??(isActive?state.trainingSessions:0);
    const matches=own.matches??(isActive?state.matches.length:0);
    const bestStreak=own.bestStreak??(isActive?state.streak:0);
    const reviewWords=own.reviewWords??(isActive?state.reviewWords:[]);
    const accuracy=own.accuracy??(sessions?Math.min(98,72+sessions*2):0);
    return {sessions,matches,bestStreak,reviewWords,accuracy,wordsPractised:own.wordsPractised??sessions*5,lastMode:own.lastMode||'Hear & Spell'};
  }
  function renderLearnerProfile(p,{parentView=false}={}){
    const journey=learnerJourney(p),pathway=state.settings.learnerLevel||'Foundation',pathProgress=Math.min(100,journey.sessions*12),nextMilestone=journey.sessions===0?'Complete the first practice':journey.sessions<5?'Build a five-session rhythm':journey.sessions<10?'Strengthen recall without prompts':'Prepare for competition recall';
    const actions=parentView?`<button class="btn" data-action="back-to-parent-profile">${icon('chevron')} Parent profile</button>`:`<button class="btn" data-action="edit-profile">${icon('edit')} Edit profile</button>`;
    return `<main class="page learner-profile-page">${pageHead('Learner profile',p.nickname,'Learning journey, practice progress, and competition readiness.',actions)}
      <div class="grid profile-detail-grid">
        <aside class="card profile-identity-card">
          <span class="avatar profile-avatar">${p.avatar||initials(p.nickname)}</span><h3>${p.nickname}</h3><p>${p.grade} · ${p.country}</p>
          <div class="badge rank">Bronze I · ${state.rank}</div>
          <div class="learner-path-label"><span>${pathway} pathway</span><strong>${pathProgress}%</strong></div>
          <div class="progress"><span style="width:${pathProgress}%"></span></div>
          <small class="learner-next-step">${nextMilestone}</small>
        </aside>
        <section>
          <div class="grid grid-4 learner-summary-grid">
            <div class="card stat"><small>Accuracy</small><div class="value">${journey.accuracy}%</div></div>
            <div class="card stat"><small>Sessions</small><div class="value">${journey.sessions}</div></div>
            <div class="card stat"><small>Words practised</small><div class="value">${journey.wordsPractised}</div></div>
            <div class="card stat"><small>Best streak</small><div class="value">${journey.bestStreak}</div></div>
          </div>
          <div class="grid grid-2 learner-journey-grid">
            <section class="card">
              <div class="learner-card-heading"><span>${icon('dumbbell')}</span><div><small>Current focus</small><h3>${journey.lastMode}</h3></div></div>
              <div class="journey-step ${journey.sessions>0?'complete':'current'}"><i>${journey.sessions>0?icon('check'):'1'}</i><div><strong>Learn the word</strong><small>Pronunciation, spelling, and meaning</small></div></div>
              <div class="journey-step ${journey.sessions>=5?'complete':journey.sessions>0?'current':''}"><i>${journey.sessions>=5?icon('check'):'2'}</i><div><strong>Build reliable recall</strong><small>Spell with fewer visual prompts</small></div></div>
              <div class="journey-step ${journey.sessions>=10?'current':''}"><i>3</i><div><strong>Competition readiness</strong><small>Recall accurately under pressure</small></div></div>
            </section>
            <section class="card">
              <div class="learner-card-heading"><span>${icon('refresh')}</span><div><small>Needs attention</small><h3>Review words</h3></div></div>
              <div class="learner-review-words">${journey.reviewWords.map(word=>`<span class="badge">${word}</span>`).join('')||'<p class="muted">Nothing waiting for review.</p>'}</div>
              <div class="learner-review-footer"><span>${icon('trophy')} ${journey.matches} competition ${journey.matches===1?'match':'matches'}</span><span>${icon('clock')} ${journey.bestStreak} best streak</span></div>
            </section>
          </div>
          <div class="section-head"><h3>Recent learning</h3></div>
          <div class="card">${journey.sessions||journey.matches?recentActivity():'<div class="empty-state compact"><span class="avatar">'+icon('flag')+'</span><h3>Journey begins here</h3><p>The learner’s completed sessions and milestones will appear here.</p></div>'}</div>
        </section>
      </div>
    </main>`;
  }
  function renderProfile(){
    if(!isParentAccount())return renderLearnerProfile(profile());
    const viewed=runtime.viewedLearnerId&&state.profiles.find(item=>item.id===runtime.viewedLearnerId);
    if(viewed)return renderLearnerProfile(viewed,{parentView:true});
    const owner=state.accountOwner||{},name=owner.name||services.firebase.user?.displayName||services.firebase.user?.email?.split('@')[0]||'Parent',country=owner.country||profile().country||'Nigeria';
    return `<main class="page">${pageHead('Account owner','Your profile','Manage your account and the learners connected to it.',`<button class="btn" data-action="edit-profile">${icon('edit')} Edit profile</button>`)}
      <div class="grid parent-profile-grid">
        <aside class="card profile-identity-card parent-identity-card">
          <span class="avatar profile-avatar">${initials(name)}</span>
          <h3>${name}</h3>
          <p>Parent · ${country}</p>
          <span class="badge">Account owner</span>
        </aside>
        <section>
          <div class="section-head"><h3>Learners</h3><button class="btn btn-primary btn-sm" data-action="add-learner">${icon('plus')} Add learner</button></div>
          <div class="card parent-profile-learners">${state.profiles.map(learner=>`<div class="list-row"><span class="avatar">${learner.avatar||initials(learner.nickname)}</span><div class="list-main"><strong>${learner.nickname}</strong><small>${learner.grade} · Rating ${state.rank}</small></div><button class="btn btn-sm" data-action="view-learner" data-view-learner-id="${learner.id}">View learner</button></div>`).join('')||'<p class="muted">No learner profiles yet.</p>'}</div>
          <div class="section-head"><h3>Account</h3></div>
          <div class="card parent-account-actions"><div class="list-row"><span class="avatar">${icon('users')}</span><div class="list-main"><strong>Active learner</strong><small>${profile().nickname}</small></div><button class="btn btn-sm" data-action="switch-profile">Switch learner</button></div><div class="list-row"><span class="avatar">${icon('settings')}</span><div class="list-main"><strong>Preferences</strong><small>Safety, training, and account settings</small></div><button class="btn btn-sm" data-nav="settings">Open</button></div></div>
        </section>
      </div>
    </main>`;
  }

  function renderRankings(){
    const uid=services.firebase.user?.uid,rows=runtime.live.leaderboard,position=rows.findIndex(row=>row.id===uid)+1,rating=runtime.live.player?.rating||state.rank;
    return `<main class="page">${pageHead('Competitive standings','Rankings','Verified match results')}<div class="grid grid-3"><div class="card stat"><small>Your rating</small><div class="value">${rating}</div><span class="badge rank">Live</span></div><div class="card stat"><small>Position</small><div class="value">${position>0?`#${position}`:'—'}</div></div><div class="card stat"><small>Matches</small><div class="value">${runtime.live.player?.matchCount||0}</div></div></div><div class="card table-wrap" style="margin-top:18px"><table class="table"><thead><tr><th>Rank</th><th>Speller</th><th>Region</th><th class="right">Rating</th><th class="right">Matches</th></tr></thead><tbody>${rows.map((row,index)=>`<tr class="${row.id===uid?'me':''}"><td><strong>${index+1}</strong></td><td>${row.nickname||row.displayName||'Speller'} ${row.id===uid?'<span class="badge">You</span>':''}</td><td>${row.country||'—'}</td><td class="right"><strong>${row.rating||1200}</strong></td><td class="right">${row.matchCount||0}</td></tr>`).join('')||'<tr><td colspan="5">No ranked players yet.</td></tr>'}</tbody></table></div></main>`;
  }
  function renderSocial(){
    const uid=services.firebase.user?.uid,friends=runtime.live.friends.map(item=>{const other=item.memberUids.find(id=>id!==uid);return{id:other,...(item.profiles?.[other]||{})};}),requests=runtime.live.friendRequests.filter(item=>item.status==='pending');
    return `<main class="page">${pageHead('Controlled network','Friends & teams',`Your code: ${runtime.live.player?.friendCode||'—'}`,`<button class="btn btn-primary" data-action="add-friend">${icon('plus')} Add friend</button>`)}<div class="grid grid-2"><section><div class="section-head"><h3>Friends</h3><span class="badge">${friends.length}</span></div><div class="card">${friends.map(friend=>`<div class="list-row"><span class="avatar">${initials(friend.nickname||friend.displayName)}</span><div class="list-main"><strong>${friend.nickname||friend.displayName||'Speller'}</strong><small>${friend.grade||'Alliam player'}</small></div><button class="btn btn-sm" data-action="challenge-friend" data-uid="${friend.id}">Challenge</button></div>`).join('')||'<p class="muted">Add a friend using their Alliam code.</p>'}</div></section><section><div class="section-head"><h3>Your teams</h3><button class="btn btn-ghost btn-sm" data-action="create-team">Create</button></div><div class="card">${runtime.live.teams.map(team=>`<div class="list-row"><span class="avatar">${initials(team.name)}</span><div class="list-main"><strong>${team.name}</strong><small>${team.school||'Independent'} · ${team.memberUids?.length||1} members</small></div></div>`).join('')||'<p class="muted">No team yet.</p>'}</div></section></div><div class="section-head"><h3>Requests</h3></div><div class="card">${requests.map(request=>`<div class="list-row"><span class="avatar">${initials(request.senderProfile?.nickname)}</span><div class="list-main"><strong>${request.senderProfile?.nickname||'Speller'}</strong><small>Friend request</small></div><button class="btn btn-sm" data-action="respond-friend" data-request-id="${request.id}" data-accept="true">Accept</button><button class="btn btn-sm" data-action="respond-friend" data-request-id="${request.id}">Decline</button></div>`).join('')||'<p class="muted">No pending requests.</p>'}</div></main>`;
  }
  function renderSettings(){ const s=state.settings; return `<main class="page">${pageHead('Preferences','Settings','Training, audio, recognition, privacy, and account controls.')}<div class="tabs">${['Training','Experience','Privacy & safety','Account','Services'].map(x=>`<button class="${(runtime.tab||'Training')===x?'active':''}" data-settings-tab="${x}">${x}</button>`).join('')}</div>${renderSettingsTab(runtime.tab||'Training',s)}</main>`; }
  function renderSettingsTab(tab,s){
    if(tab==='Training')return `<div class="grid grid-2"><section class="card form learner-level-card"><h3>Learner level</h3><p>Sets the overall starting point Alliam uses to choose difficulty, assistance, and session length.</p><div class="field"><label>Current pathway</label><select class="select" data-setting="learnerLevel">${['Foundation','Builder','Championship'].map(level=>`<option ${level===(s.learnerLevel||'Foundation')?'selected':''}>${level}</option>`).join('')}</select></div><small>Module-specific controls remain available inside each training session.</small></section><section class="card"><h3>How this works</h3><div class="list-row"><span class="badge">1</span><div class="list-main"><strong>Foundation</strong><small>More guidance, shorter sessions, and core vocabulary.</small></div></div><div class="list-row"><span class="badge">2</span><div class="list-main"><strong>Builder</strong><small>Balanced assistance, longer recall, and developing competition vocabulary.</small></div></div><div class="list-row"><span class="badge">3</span><div class="list-main"><strong>Championship</strong><small>Stricter recall, advanced vocabulary, and competition-oriented defaults.</small></div></div></section></div>`;
    if(tab==='Experience')return `<div class="grid grid-2"><section class="card form"><h3>Audio</h3><div class="field"><label>Voice</label><select class="select" data-setting="voice"><option>${s.voice}</option><option>Alliam Two</option></select></div><div class="field"><label>Playback speed</label><select class="select" data-setting="speed"><option>${s.speed}</option><option>Slow</option><option>Fast</option></select></div><div class="field"><label>Volume · ${s.volume}%</label><input type="range" min="0" max="100" value="${s.volume}" data-setting="volume" /></div>${toggle('effects','Sound effects',s.effects)}</section><section class="card form"><h3>Recognition & accessibility</h3><div class="field"><label>English locale</label><select class="select" data-setting="locale"><option value="en-NG" ${s.locale==='en-NG'?'selected':''}>English — Nigeria</option><option value="en-GB">English — United Kingdom</option><option value="en-US">English — United States</option></select></div><button class="btn" data-action="mic-test">${icon('mic')} Run microphone test</button>${toggle('reducedMotion','Reduced motion',s.reducedMotion)}${toggle('highContrast','High contrast',s.highContrast)}</section><section class="card"><h3>Notifications</h3>${toggle('matchAlerts','Match reminders',s.matchAlerts)}${toggle('inviteAlerts','Invitations',s.inviteAlerts)}${toggle('rankAlerts','Rank changes',s.rankAlerts)}</section></div>`;
    if(tab==='Privacy & safety')return `<div class="grid grid-2"><section class="card form"><h3>Visibility</h3><div class="field"><label>Profile visibility</label><select class="select" data-setting="profileVisibility"><option>${s.profileVisibility}</option><option>Friends only</option><option>Private</option></select></div>${toggle('friendRequests','Allow friend requests',s.friendRequests)}${toggle('audioRetention','Keep match audio for disputed results',s.audioRetention)}</section><section class="card"><h3>Safety controls</h3><div class="list-row"><div class="list-main"><strong>Blocked users</strong><small>Manage people this profile cannot interact with.</small></div><button class="btn btn-sm">Manage</button></div><div class="list-row"><div class="list-main"><strong>Reports</strong><small>Review safety reports submitted from this profile.</small></div><button class="btn btn-sm">View</button></div><div class="list-row"><div class="list-main"><strong>Parent controls</strong><small>Competition, social, and audio permissions.</small></div><button class="btn btn-sm" data-nav="parent">Open</button></div></section></div>`;
    if(tab==='Account')return `<div class="grid grid-2"><section class="card"><h3>Profile access</h3><div class="list-row"><div class="list-main"><strong>Local prototype account</strong><small>Firebase Authentication will replace local persistence.</small></div><span class="badge rank">Local</span></div><button class="btn" data-action="switch-profile">Switch learner</button><button class="btn" data-action="export-data">Export local data</button></section><section class="card"><h3>Account lifecycle</h3><div class="list-row"><div class="list-main"><strong>Sign out</strong><small>Return to the profile access screen.</small></div><button class="btn" data-action="sign-out">Sign out</button></div><div class="list-row"><div class="list-main"><strong>Delete account</strong><small>Remove this local profile and associated data.</small></div><button class="btn btn-danger" data-action="delete-account">Delete</button></div></section></div>`;
    return renderServices();
  }
  function toggle(key,label,checked){return `<div class="switch-row"><strong>${label}</strong><label class="switch"><input type="checkbox" data-toggle-setting="${key}" ${checked?'checked':''}/><span></span></label></div>`;}
  function renderServices(){ const cfg=window.ALLIAM_CONFIG; return `<div class="grid grid-3"><section class="card"><div class="service-status"><i class="status-dot ${cfg.firebase.enabled?'ready':'placeholder'}"></i><h3>Firebase</h3></div><p>Authentication, Firestore, Storage, Functions, App Check.</p><div class="list-row"><div class="list-main"><small>Project</small><strong>${cfg.firebase.enabled?cfg.firebase.projectId:'Not configured'}</strong></div></div><span class="badge ${cfg.firebase.enabled?'good':'rank'}">${cfg.firebase.enabled?'Connected':'Placeholder'}</span></section><section class="card"><div class="service-status"><i class="status-dot ${cfg.elevenLabs.enabled?'ready':'placeholder'}"></i><h3>ElevenLabs</h3></div><p>Pre-generated branded word and prompt audio.</p><div class="list-row"><div class="list-main"><small>Runtime fallback</small><strong>Browser speech synthesis</strong></div></div><span class="badge ${cfg.elevenLabs.enabled?'good':'rank'}">${cfg.elevenLabs.enabled?'Connected':'Placeholder'}</span></section><section class="card"><div class="service-status"><i class="status-dot ${cfg.microsoftSpeech.enabled?'ready':'placeholder'}"></i><h3>Microsoft Speech</h3></div><p>Live letter recognition through short-lived backend tokens.</p><div class="list-row"><div class="list-main"><small>Locale</small><strong>${state.settings.locale}</strong></div></div><span class="badge ${cfg.microsoftSpeech.enabled?'good':'rank'}">${cfg.microsoftSpeech.enabled?'Connected':'Placeholder'}</span></section><section class="card" style="grid-column:1/-1"><h3>Integration files</h3><p>Enter public configuration in <span class="code">config.js</span>. Keep ElevenLabs and Azure secrets in Firebase Functions—never in this app.</p></section></div>`; }

  function renderParent(){ const p=profile();return `<main class="page">${pageHead('Adult supervision','Parent dashboard','Manage learner access, safety, and progress.',`<button class="btn btn-primary" data-action="add-learner">${icon('plus')} Add learner</button>`)}<div class="grid grid-3"><div class="card stat"><small>Learners</small><div class="value">${state.profiles.length}</div></div><div class="card stat"><small>Matches this week</small><div class="value">${state.matches.length}</div></div><div class="card stat"><small>Words reviewed</small><div class="value">${state.trainingSessions*5}</div></div></div><div class="grid grid-2" style="margin-top:18px"><section class="card"><h3>Learner profiles</h3>${state.profiles.map(x=>`<div class="list-row ${x.id===state.activeProfileId?'active-learner':''}"><span class="avatar">${x.avatar}</span><div class="list-main"><strong>${x.nickname}</strong><small>${x.grade} · Rating ${state.rank}</small></div><button class="btn btn-sm" data-action="view-learner" data-view-learner-id="${x.id}">View learner</button></div>`).join('')}</section><section class="card"><h3>Permissions for ${p.nickname}</h3>${toggle('parentCompetition','Online competition',true)}${toggle('parentFriends','Friend requests',state.settings.friendRequests)}${toggle('parentAudio','Audio retention',state.settings.audioRetention)}</section></div></main>`; }
  function renderSchool(){ return `<main class="page">${pageHead('Organized competition','School hub','Rosters, teams, word packs, fixtures, and results.',`<button class="btn btn-primary" data-action="create-event">${icon('plus')} Create event</button>`)}<div class="grid grid-4"><div class="card stat"><small>Students</small><div class="value">24</div></div><div class="card stat"><small>Teams</small><div class="value">4</div></div><div class="card stat"><small>Fixtures</small><div class="value">3</div></div><div class="card stat"><small>School rank</small><div class="value">#18</div></div></div><div class="grid grid-2" style="margin-top:18px"><section class="card"><h3>Upcoming fixtures</h3><div class="list-row"><span class="avatar">EP</span><div class="list-main"><strong>Emerald vs Blue House</strong><small>Friday · 12:30 · 6v6</small></div><span class="badge live">Scheduled</span></div><div class="list-row"><span class="avatar">DP</span><div class="list-main"><strong>District qualifier</strong><small>Saturday · Online bracket</small></div><span class="badge">Check-in soon</span></div></section><section class="card"><h3>Team roster</h3>${['Ada M.','Tobi A.','Maya E.','David O.','Zuri N.','Kwame A.'].map((n,i)=>`<div class="list-row"><span class="rank-num">${i+1}</span><div class="list-main"><strong>${n}</strong><small>${i<3?'Starter':'Reserve'}</small></div><span class="badge rank">${1500-i*23}</span></div>`).join('')}</section></div></main>`; }
  function renderAdmin(){ const audioReady=WORDS.filter(word=>word.audio?.normal).length;return `<main class="page">${pageHead('Internal operations','Content & administration','Manage word packs, generated voice assets, and match operations.',`<button class="btn btn-primary" data-action="add-word">${icon('plus')} Add word</button>`)}${runtime.audioMessage?`<div class="card"><strong>Audio pipeline</strong><p>${runtime.audioMessage}</p></div>`:''}<div class="grid grid-4"><div class="card stat"><small>Words</small><div class="value">${WORDS.length}</div></div><div class="card stat"><small>Word audio</small><div class="value">${audioReady}</div><span class="badge ${audioReady===WORDS.length?'good':'rank'}">${audioReady===WORDS.length?'Ready':'Generation needed'}</span></div><div class="card stat"><small>Alphabet audio</small><div class="value">${runtime.alphabetReady||0}/26</div><span class="badge ${(runtime.alphabetReady||0)===26?'good':'rank'}">${(runtime.alphabetReady||0)===26?'Ready':'Generation needed'}</span></div><div class="card stat"><small>Review holds</small><div class="value">0</div></div></div><div class="tabs" style="margin-top:25px"><button class="active">Word library</button><button>Audio pipeline</button><button>Releases</button><button>Match operations</button><button>Moderation</button></div><div class="card table-wrap"><table class="table"><thead><tr><th>Word</th><th>Level</th><th>Origin</th><th>Audio</th><th class="right">Action</th></tr></thead><tbody>${WORDS.map(w=>`<tr><td><strong>${w.word}</strong></td><td>${w.level}</td><td>${w.origin}</td><td><span class="badge ${w.audio?.normal?'good':'rank'}">${w.audio?.normal?'Generated':'Needs generation'}</span></td><td class="right"><button class="btn btn-sm" data-action="play-admin-word" data-word="${w.word}">${icon('volume')} Play</button> <button class="btn btn-sm" data-action="edit-word" data-word="${w.word}">Edit</button></td></tr>`).join('')}</tbody></table></div></main>`; }
  function renderNotifications(){ return `<main class="page">${pageHead('Updates','Notifications','Invites, match results, rank movement, and event reminders.',`<button class="btn" data-action="mark-read">Mark all read</button>`)}<div class="card">${state.notifications.map(n=>`<div class="list-row"><span class="avatar">${n.type==='invite'?'1v1':'D'}</span><div class="list-main"><strong>${n.text}</strong><small>${n.read?'Read':'New'}</small></div>${n.type==='invite'?'<button class="btn btn-sm" data-action="accept-challenge">Open</button>':''}</div>`).join('')}</div></main>`; }

  function renderSchool(){
    const events=runtime.live.events,teams=runtime.live.teams;
    return `<main class="page">${pageHead('Organized competition','School hub','Live teams and scheduled events',`<button class="btn btn-primary" data-action="create-event">${icon('plus')} Create event</button>`)}<div class="grid grid-3"><div class="card stat"><small>Teams</small><div class="value">${teams.length}</div></div><div class="card stat"><small>Events</small><div class="value">${events.length}</div></div><div class="card stat"><small>School</small><div class="value">${profile().school?initials(profile().school):'—'}</div></div></div><div class="grid grid-2" style="margin-top:18px"><section class="card"><h3>Events</h3>${events.map(event=>`<div class="list-row"><span class="avatar">${initials(event.title)}</span><div class="list-main"><strong>${event.title}</strong><small>${event.startsAt||'Date pending'} · ${event.type}</small></div><span class="badge">${event.status}</span></div>`).join('')||'<p class="muted">No events scheduled.</p>'}</section><section class="card"><h3>Teams</h3>${teams.map(team=>`<div class="list-row"><span class="avatar">${initials(team.name)}</span><div class="list-main"><strong>${team.name}</strong><small>${team.memberUids?.length||1} members</small></div><span class="badge rank">${team.rating||1200}</span></div>`).join('')||'<p class="muted">No school teams yet.</p>'}</section></div></main>`;
  }
  function renderModal(){ const m=runtime.modal;if(!m)return''; let body='';
    if(m.type==='training-config'){
      const s=runtime.trainingSetup,config=trainingConfigFor(s.mode),requiresAudio=!['Word Flash','Missing Letters','Build the Word'].includes(s.mode);
      body=`<section class="train-options train-config-card training-config-dialog is-updated" aria-label="Session options">
        <header class="train-config-head"><span class="train-config-mark">${icon('settings')}</span><div><h3>${s.mode}</h3><small>Session setup</small></div></header>
        <div class="train-config-fields">
          <div class="field"><label for="trainingLevel">${config.levelLabel}</label><select class="select" id="trainingLevel">${config.levels.map(x=>`<option ${s.level===x?'selected':''}>${x}</option>`).join('')}</select></div>
          <div class="field"><label for="trainingCount">${config.countLabel}</label><select class="select" id="trainingCount">${config.counts.map(x=>`<option value="${x}" ${Number(s.count)===x?'selected':''}>${x}</option>`).join('')}</select></div>
          <div class="field train-assistance"><label for="trainingAssistance">${config.optionLabel}</label><select class="select" id="trainingAssistance">${config.options.map(x=>`<option ${s.assistance===x?'selected':''}>${x}</option>`).join('')}</select></div>
          <div class="field train-pressure"><label for="trainingPressure">Environment</label><select class="select" id="trainingPressure"><option value="calm">Calm practice</option><option value="pressure" ${s.pressure?'selected':''}>Pressure Chamber</option></select></div>
        </div>
        <footer class="train-config-action"><button class="train-start" data-action="${m.fromSession?'apply-session-config':'start-training'}"><span>${m.fromSession?'Save & restart':'Go'}</span></button>${requiresAudio&&runtime.audioStatus==='error'?`<small class="audio-load-error">${runtime.audioError}</small>`:''}</footer>
      </section>`;
    }
    if(m.type==='menu')body=`<div class="list"><button class="list-row btn btn-ghost" data-nav="parent">${icon('shield')} Parent dashboard</button><button class="list-row btn btn-ghost" data-nav="school">${icon('school')} School hub</button><button class="list-row btn btn-ghost" data-nav="admin">${icon('database')} Content administration</button><button class="list-row btn btn-ghost" data-nav="settings">${icon('settings')} Settings</button></div>`;
    if(m.type==='private')body=`<div class="form"><div class="field"><label>Join with a room code</label><input class="input" id="roomCode" placeholder="Enter code" maxlength="8" /></div><button class="btn btn-primary" data-action="join-room">Join room</button><div class="list-row"><div class="list-main"><strong>Create a private room</strong><small>Invite a friend using a safe match code.</small></div><button class="btn" data-action="create-room">Create</button></div></div>`;
    if(m.type==='friend')body=`<div class="form"><div class="field"><label>Friend code</label><input class="input" id="friendCode" placeholder="e.g. ADA-2841" /></div><button class="btn btn-primary" data-action="send-friend-request">Send request</button></div>`;
    if(m.type==='profile'){const editingParent=isParentAccount()&&!runtime.viewedLearnerId;const subject=editingParent?(state.accountOwner||{}):profile();body=`<div class="form"><div class="field"><label>${editingParent?'Parent name':'Competition nickname'}</label><input class="input" id="editNickname" value="${editingParent?(subject.name||''):subject.nickname}" /></div>${editingParent?`<div class="field"><label>Country</label><input class="input" id="editCountry" value="${subject.country||'Nigeria'}" /></div>`:`<div class="field"><label>School</label><input class="input" id="editSchool" value="${subject.school||''}" /></div>`}<button class="btn btn-primary" data-action="save-profile">Save changes</button></div>`;}
    if(m.type==='profiles')body=`<div class="learner-picker-list" role="list">${state.profiles.map(p=>`<button class="profile-picker ${p.id===state.activeProfileId?'active':''}" data-profile-id="${p.id}" aria-pressed="${p.id===state.activeProfileId}"><span class="avatar">${p.avatar}</span><span class="profile-picker-copy"><strong>${p.nickname}</strong><small>${p.grade}</small></span><span class="profile-picker-status" aria-hidden="true">${p.id===state.activeProfileId?icon('check'):''}</span></button>`).join('')}</div><button class="btn btn-primary learner-picker-add" data-action="open-add-learner">${icon('plus')} Add learner</button>`;
    if(m.type==='learner')body=`<div class="form"><div class="field"><label for="learnerName">Name or nickname</label><input class="input" id="learnerName" required placeholder="New speller" /></div><div class="field"><label for="learnerGrade">Grade</label><select class="select" id="learnerGrade">${[1,2,3,4,5,6,7,8].map(n=>`<option>Grade ${n}</option>`).join('')}</select></div><button class="btn btn-primary" data-action="save-learner">${icon('plus')} Add learner</button></div>`;
    if(m.type==='team')body=`<div class="form"><div class="field"><label for="teamName">Team name</label><input class="input" id="teamName" placeholder="Emerald Spellers" /></div><div class="field"><label for="teamSchool">School</label><input class="input" id="teamSchool" value="${profile().school||''}" /></div><button class="btn btn-primary" data-action="save-team">${icon('check')} Create team</button></div>`;
    if(m.type==='event')body=`<div class="form"><div class="field"><label for="eventName">Event name</label><input class="input" id="eventName" placeholder="District warm-up" /></div><div class="grid grid-2"><div class="field"><label for="eventDate">Date</label><input class="input" id="eventDate" type="date" /></div><div class="field"><label for="eventFormat">Format</label><select class="select" id="eventFormat"><option>1v1</option><option>6v6</option><option>Tournament</option></select></div></div><button class="btn btn-primary" data-action="save-event">${icon('check')} Save event</button></div>`;
    if(m.type==='word'){const existing=allWords().find(word=>word.word===m.word)||{};body=`<div class="form"><div class="grid grid-2"><div class="field"><label for="wordText">Word</label><input class="input" id="wordText" value="${existing.word||''}" /></div><div class="field"><label for="wordLevel">Level</label><select class="select" id="wordLevel">${['Foundation','Builder','Championship'].map(level=>`<option ${existing.level===level?'selected':''}>${level}</option>`).join('')}</select></div></div><div class="field"><label for="wordDefinition">Definition</label><textarea class="textarea" id="wordDefinition">${existing.definition||''}</textarea></div><div class="field"><label for="wordSentence">Example sentence</label><textarea class="textarea" id="wordSentence">${existing.sentence||''}</textarea></div><div class="grid grid-2"><div class="field"><label for="wordPart">Part of speech</label><input class="input" id="wordPart" value="${existing.part||''}" /></div><div class="field"><label for="wordOrigin">Origin</label><input class="input" id="wordOrigin" value="${existing.origin||''}" /></div></div><button class="btn btn-primary" data-action="save-word">${icon('check')} Save word</button></div>`;}
    return `<div class="modal-backdrop" data-action="close-modal"><section class="modal ${m.type==='training-config'?'training-config-modal':''}" role="dialog" aria-modal="true"><div class="modal-head"><h3>${m.title||'Alliam'}</h3><button class="btn btn-icon btn-ghost" data-action="close-modal">${icon('x')}</button></div>${body}</section></div>`;
  }

  async function handleAction(action,target){
    if(action==='landing-home'){navigate('landing');return;}
    if(action==='landing-signin'){window.location.assign(`${window.ALLIAM_CONFIG?.appUrl||'https://alliam-app-ad3fd.web.app/#'}/?mode=signin`);return;}
    if(action==='landing-start'){window.location.assign(`${window.ALLIAM_CONFIG?.appUrl||'https://alliam-app-ad3fd.web.app/#'}/?mode=signup`);return;}
    if(action==='landing-train'){window.location.assign(`${window.ALLIAM_CONFIG?.appUrl||'https://alliam-app-ad3fd.web.app/#'}/train`);return;}
    if(action==='landing-compete'){window.location.assign(`${window.ALLIAM_CONFIG?.appUrl||'https://alliam-app-ad3fd.web.app/#'}/compete`);return;}
    if(action==='toggle-auth-mode'){runtime.authMode=runtime.authMode==='signin'?'signup':'signin';render();return;}
    if(action==='landing-menu'){document.querySelector('.landing-header')?.classList.toggle('menu-open');return;}
    if(action==='onboard-next'){
      const o=runtime.onboarding;
      if(o.role==='school'){
        if(runtime.onboardingStep===1){
          o.schoolName=document.querySelector('#obSchoolName')?.value.trim()||'';
          o.adminName=document.querySelector('#obAdminName')?.value.trim()||o.nickname||'Administrator';
          o.country=document.querySelector('#obCountry')?.value||'Nigeria';
          if(!o.schoolName){toast('Enter the school or organisation name.');return;}
        }
        if(runtime.onboardingStep<2){runtime.onboardingStep++;render();}else{completeOnboarding();}
        return;
      }
      const soundStep=o.role==='parent'?3:2;
      if(runtime.onboardingStep===soundStep&&document.querySelector('#consentCheck')&&!document.querySelector('#consentCheck').checked){toast('Parent or guardian consent is required for child voice features.');return;}
      if(o.role==='parent'&&runtime.onboardingStep===1){o.guardianName=document.querySelector('#obGuardianName')?.value.trim()||o.nickname||'Parent';o.country=document.querySelector('#obCountry')?.value||'Nigeria';}
      const learnerStep=o.role==='parent'?2:1;
      if(runtime.onboardingStep===learnerStep){const name=document.querySelector('#obName')?.value.trim()||'Ada';if(o.role==='parent')o.learnerName=name;else o.nickname=name;o.grade=document.querySelector('#obGrade')?.value||'Grade 1';o.country=document.querySelector('#obCountry')?.value||o.country||'Nigeria';o.school=document.querySelector('#obSchool')?.value.trim()||'';o.avatar=(o.avatar||name[0]||'A').toUpperCase();}
      const lastStep=o.role==='parent'?4:3;
      if(runtime.onboardingStep<lastStep){runtime.onboardingStep++;render();}else{completeOnboarding();} return;
    }
    if(action==='onboard-back'){runtime.onboardingStep=Math.max(0,runtime.onboardingStep-1);render();return;}
    if(action==='load-demo'){
      if(runtime.authBusy)return;
      runtime.authBusy=true;
      runtime.onboarding={role:'student',nickname:'Ada',grade:'Grade 1',country:'Nigeria',school:'Demo Primary School',avatar:'A'};
      completeOnboarding(true);
      runtime.authBusy=false;
      return;
    }
    if(action==='speaker-test'){services.audio.speak('Welcome to Alliam. Your word is apple.');toast('Playing the audio test.');return;}
    if(action==='open-menu'){runtime.modal={type:'menu',title:'Menu'};render();return;}
    if(action==='toggle-sidebar'){runtime.sidebarCollapsed=!runtime.sidebarCollapsed;localStorage.setItem('alliam-sidebar-collapsed',String(runtime.sidebarCollapsed));render();return;}
    if(action==='toggle-mobile-menu'){runtime.mobileMenu=!runtime.mobileMenu;render();return;}
    if(action==='close-modal'){runtime.modal=null;render();return;}
    if(action==='quick-train'||action==='review-words'){if(action==='review-words')runtime.trainingSetup.mode='Missed Words';createSession();navigate('train-session');return;}
    if(action==='open-session-settings'){runtime.modal={type:'training-config',title:`${runtime.trainingSetup.mode} settings`,fromSession:true};render();return;}
    if(action==='apply-session-config'){runtime.trainingSetup.level=document.querySelector('#trainingLevel')?.value||runtime.trainingSetup.level;runtime.trainingSetup.count=Number(document.querySelector('#trainingCount')?.value||runtime.trainingSetup.count);runtime.trainingSetup.assistance=document.querySelector('#trainingAssistance')?.value||runtime.trainingSetup.assistance;runtime.trainingSetup.pressure=document.querySelector('#trainingPressure')?.value==='pressure';if(!['Word Flash','Missing Letters','Build the Word'].includes(runtime.trainingSetup.mode)&&!await ensureRecordedAudio())return;clearTrainingTimer();runtime.modal=null;createSession();render();if(['Hear & Spell','Word Flash','Timed Drill'].includes(runtime.trainingSetup.mode))setTimeout(()=>beginTrainingExercise(),firstExerciseDelay(runtime.trainingSetup.mode));return;}
    if(action==='start-training'){runtime.trainingSetup.level=document.querySelector('#trainingLevel')?.value||runtime.trainingSetup.level;runtime.trainingSetup.count=Number(document.querySelector('#trainingCount')?.value||5);runtime.trainingSetup.assistance=document.querySelector('#trainingAssistance')?.value||runtime.trainingSetup.assistance;runtime.trainingSetup.pressure=document.querySelector('#trainingPressure')?.value==='pressure';if(!['Word Flash','Missing Letters','Build the Word'].includes(runtime.trainingSetup.mode)&&!await ensureRecordedAudio())return;runtime.modal=null;createSession();navigate('train-session');if(['Hear & Spell','Word Flash','Timed Drill'].includes(runtime.trainingSetup.mode))setTimeout(()=>beginTrainingExercise(),firstExerciseDelay(runtime.trainingSetup.mode));return;}
    if(action==='begin-training-mode'||action==='teach-word'){await beginTrainingExercise();return;}
    if(action==='play-word'){services.audio.playWord(runtime.session.words[runtime.session.index]);return;}
    if(action==='skip-training'){recordTrainingAttempt(false,'');return;}
    if(action==='undo-letter'){runtime.session.attempt.pop();render();return;}
    if(action==='submit-attempt'){const s=runtime.session,attempt=s.attempt.join('');recordTrainingAttempt(attempt===(s.expectedAnswer||s.words[s.index].word),attempt);return;}
    if(action==='speech-placeholder'){startSpeechAttempt();return;}
    if(action==='reflash-word'){
      const s=runtime.session;if(!s||runtime.trainingSetup.mode!=='Word Flash'||s.phase!=='attempt'||(s.usedRequests||[]).includes('reflash'))return;
      s.usedRequests=[...(s.usedRequests||[]),'reflash'];s.phase='teaching';s.animateBoxes=true;render();
      await services.delay((parseInt(runtime.trainingSetup.assistance,10)||3)*1000);
      if(runtime.session===s){s.phase='attempt';s.animateBoxes=true;render();}
      return;
    }
    if(action==='next-training-word'){clearTrainingTimer();document.querySelector('.train-diamonds')?.classList.add('is-exiting');await services.delay(240);const s=runtime.session;if((runtime.trainingSetup.mode==='Survival Run'&&s.lives<=0)||s.index>=s.words.length-1){state.trainingSessions++;state.score+=s.correct*10;saveLearnerTrainingJourney(s);saveState();navigate('train-result');}else{s.index++;s.position=0;s.attempt=[];s.phase='ready';s.secondsLeft=null;s.countdown=null;s.infoType=null;s.usedRequests=[];s.reflashes=0;s.animateBoxes=true;prepareModeWord(s);render();if(['Hear & Spell','Word Flash','Timed Drill'].includes(runtime.trainingSetup.mode))setTimeout(()=>beginTrainingExercise(),nextExerciseDelay(runtime.trainingSetup.mode));}return;}
    if(action==='previous-training-word'||action==='next-session-word'){
      const s=runtime.session;if(!s)return;
      const direction=action==='previous-training-word'?-1:1;
      const index=Math.max(0,Math.min(s.words.length-1,s.index+direction));
      if(index===s.index)return;
      clearTrainingTimer();await services.speech.stop();document.querySelector('.train-diamonds')?.classList.add('is-exiting');await services.delay(220);
      s.index=index;s.position=0;s.attempt=[];s.phase='ready';s.secondsLeft=null;s.countdown=null;s.infoType=null;s.usedRequests=[];s.reflashes=0;s.animateBoxes=true;render();if(['Hear & Spell','Word Flash','Timed Drill'].includes(runtime.trainingSetup.mode))setTimeout(()=>beginTrainingExercise(),nextExerciseDelay(runtime.trainingSetup.mode));return;
    }
    if(action==='finish-training'){runtime.session=null;navigate('home');return;}
    if(action==='exit-session'){clearTrainingTimer();runtime.session=null;navigate('train');return;}
    if(action==='quick-match'||action==='casual-match'||action==='accept-challenge'){beginMatch('Casual 1v1');return;}
    if(action==='respond-invitation'){try{const result=await services.firebase.respondInvitation(target.dataset.invitationId,target.dataset.accept==='true');if(result.matchId)subscribeToMatch(result.matchId);else toast('Invitation declined.');}catch(error){toast(error.message);}return;}
    if(action==='ranked-match'){beginMatch('Ranked 1v1');return;}
    if(action==='private-room'){runtime.modal={type:'private',title:'Private match'};render();return;}
    if(action==='create-room'){try{const result=await services.firebase.createPrivateRoom();toast(`Room code: ${result.code}`);}catch(error){toast(error.message);}return;}
    if(action==='join-room'){const code=document.querySelector('#roomCode')?.value.trim();if(!code){toast('Enter a room code.');return;}try{const result=await services.firebase.joinPrivateRoom(code);runtime.modal=null;subscribeToMatch(result.matchId);}catch(error){toast(error.message);}return;}
    if(action==='team-match'){beginMatch('Team 6v6');return;}
    if(action==='school-match'||action==='tournament'){toast('This organized match is scheduled through the School hub.');navigate('school');return;}
    if(action==='start-match'){runtime.competition.phase='playing';services.audio.playWord(runtime.competition.word);render();return;}
    if(action==='undo-match-letter'){runtime.competition.attempt.pop();render();return;}
    if(action==='submit-match'){const m=runtime.competition;if(!m.matchId){toast('The live match is not ready.');return;}try{await services.firebase.submitMatchRound(m.matchId,m.attempt.join(''));m.phase='waiting';render();}catch(error){toast(error.message);}return;}
    if(action==='next-match-round'){const m=runtime.competition;if(m.serverStatus==='completed'){navigate('match-result');return;}m.phase='waiting';render();return;}
    if(action==='leave-match'){
      const match=runtime.competition;
      if(match?.phase==='queue'){
        if(confirm('Cancel matchmaking and leave the queue?')){await services.firebase.cancelMatchQueue().catch(()=>{});runtime.matchUnsubscribe?.();runtime.competition=null;navigate('compete');}
        return;
      }
      if(!match?.matchId){if(confirm('Leave this match?')){runtime.competition=null;navigate('compete');}return;}
      if(!confirm('This match is active. Leaving now will forfeit the match and deduct 16 rating points. Leave anyway?'))return;
      try{
        const result=await services.firebase.forfeitMatch(match.matchId);
        match.phase='complete';match.serverStatus='completed';match.completionReason='forfeit';match.forfeitedBy=services.firebase.user?.uid;match.winnerUid=result.winnerUid;
        navigate('match-result');render();
      }catch(error){toast(error.message||'The match could not be forfeited.');}
      return;
    }
    if(action==='rematch'){beginMatch(runtime.competition.mode);return;}
    if(action==='close-match-result'){runtime.competition=null;navigate('home');return;}
    if(action==='daily'){runtime.trainingSetup={mode:'Timed Drill',level:'Foundation',count:5,assistance:'Strict'};createSession('daily');navigate('train-session');return;}
    if(action==='add-friend'){runtime.modal={type:'friend',title:'Add a friend'};render();return;}
    if(action==='send-friend-request'){const code=document.querySelector('#friendCode')?.value.trim().toUpperCase();if(!code){toast('Enter a friend code.');return;}try{await services.firebase.sendFriendRequest(code);runtime.modal=null;toast('Friend request sent.');render();}catch(error){toast(error.message);}return;}
    if(action==='respond-friend'){try{await services.firebase.respondFriendRequest(target.dataset.requestId,target.dataset.accept==='true');toast('Request updated.');}catch(error){toast(error.message);}return;}
    if(action==='challenge-friend'){try{await services.firebase.createInvitation(target.dataset.uid,'Private 1v1');toast('Challenge sent.');}catch(error){toast(error.message);}return;}
    if(action==='create-team'){runtime.modal={type:'team',title:'Create team'};render();return;}
    if(action==='save-team'){const name=document.querySelector('#teamName')?.value.trim();if(!name){toast('Enter a team name.');return;}try{await services.firebase.createTeam(name,document.querySelector('#teamSchool')?.value.trim());runtime.modal=null;toast('Team created.');}catch(error){toast(error.message);}return;}
    if(action==='edit-profile'){runtime.modal={type:'profile',title:'Edit profile'};render();return;}
    if(action==='save-profile'){
      if(isParentAccount()&&!runtime.viewedLearnerId){
        const name=document.querySelector('#editNickname')?.value.trim()||state.accountOwner?.name||'Parent';
        state.accountOwner={...(state.accountOwner||{}),name,country:document.querySelector('#editCountry')?.value.trim()||state.accountOwner?.country||'Nigeria'};
      }else{
        const p=profile();p.nickname=document.querySelector('#editNickname').value.trim()||p.nickname;p.school=document.querySelector('#editSchool').value.trim();
      }
      saveState();runtime.modal=null;render();return;
    }
    if(action==='mark-read'){state.notifications.forEach(n=>n.read=true);saveState();render();return;}
    if(action==='mic-test'){
      if(!services.speech.configured){toast('Speech recognition is not configured.');return;}
      toast('Microphone ready. Say a letter.');
      try{
        await services.speech.startLetterStream({locale:state.settings.locale,onLetters:letters=>{toast(`Heard: ${letters.map(x=>x.toUpperCase()).join(' ')}`);services.speech.stop();},onError:error=>toast(error.message)});
      }catch(error){toast(error.message||'Microphone test failed.');}
      return;
    }
    if(action==='toggle-profile-menu'){runtime.profileMenu=!runtime.profileMenu;render();return;}
    if(action==='switch-profile'){runtime.profileMenu=false;runtime.modal={type:'profiles',title:'Learners'};render();return;}
    if(action==='view-learner'){const learner=state.profiles.find(item=>item.id===target.dataset.viewLearnerId);if(!learner){toast('Learner profile not found.');return;}runtime.viewedLearnerId=learner.id;navigate('profile');render();return;}
    if(action==='back-to-parent-profile'){runtime.viewedLearnerId=null;render();return;}
    if(action==='add-learner'||action==='open-add-learner'){runtime.modal={type:'learner',title:'Add learner'};render();return;}
    if(action==='save-learner'){const nickname=document.querySelector('#learnerName')?.value.trim();if(!nickname){toast('Enter a learner name.');return;}const p={id:`p-${Date.now()}`,nickname,grade:document.querySelector('#learnerGrade')?.value||'Grade 1',country:profile().country||'Nigeria',school:profile().school||'',avatar:nickname[0].toUpperCase()};state.profiles.push(p);state.activeProfileId=p.id;saveState();runtime.modal=null;toast(`${nickname} added.`);render();return;}
    if(action==='export-data'){const blob=new Blob([JSON.stringify(state,null,2)],{type:'application/json'});const a=document.createElement('a');a.href=URL.createObjectURL(blob);a.download='alliam-data.json';a.click();URL.revokeObjectURL(a.href);return;}
    if(action==='sign-out'){services.firebase.signOut().catch(()=>{});state.initialized=false;localStorage.setItem(STORAGE_KEY,JSON.stringify(state));runtime.onboardingStep=0;navigate('landing');return;}
    if(action==='delete-account'){if(confirm('Delete this Alliam profile and its saved data?')){services.firebase.deleteAccount().catch(error=>toast(error.message));localStorage.removeItem(STORAGE_KEY);localStorage.removeItem(LEGACY_STORAGE_KEY);state=structuredClone(defaultState);render();}return;}
    if(action==='create-event'){runtime.modal={type:'event',title:'Create event'};render();return;}
    if(action==='save-event'){const name=document.querySelector('#eventName')?.value.trim();if(!name){toast('Enter an event name.');return;}try{await services.firebase.createEvent({title:name,startsAt:document.querySelector('#eventDate')?.value||'',type:document.querySelector('#eventFormat')?.value||'1v1',school:profile().school});runtime.modal=null;toast('Event saved.');}catch(error){toast(error.message);}return;}
    if(action==='add-word'||action==='edit-word'){runtime.modal={type:'word',title:action==='add-word'?'Add word':'Edit word',word:target.dataset.word||''};render();return;}
    if(action==='play-admin-word'){const entry=WORDS.find(word=>word.word===target.dataset.word);if(!entry)return;try{await services.audio.playWord(entry);}catch(error){toast(error.message);}return;}
    if(action==='approve-core-library'){runtime.audioBusy=true;runtime.audioMessage='Approving the core 60 words and their referenced audio assets…';render();try{const result=await services.firebase.approveCoreWordLibrary();runtime.audioMessage=`${result.wordCount} words and ${result.approvedAssetCount} audio assets approved.`;toast(runtime.audioMessage);}catch(error){runtime.audioMessage=error.message;console.error('Core library approval failed:',error);toast(error.message);}finally{runtime.audioBusy=false;render();}return;}
    if(action==='generate-approved-next-200'){runtime.audioBusy=true;runtime.audioMessage='Generating 200 approved pronunciations plus the queued Rhythm retry…';render();try{const result=await services.firebase.generateApprovedNext200Pronunciations();runtime.audioMessage=`${result.wordCount} new approved words generated; ${result.queuedRetryWords.join(', ')} retried.`;toast(runtime.audioMessage);}catch(error){runtime.audioMessage=error.message;console.error('Approved 200-word generation failed:',error);toast(error.message);}finally{runtime.audioBusy=false;render();}return;}
    if(action==='save-word'){const word=document.querySelector('#wordText')?.value.trim().toLowerCase();const definition=document.querySelector('#wordDefinition')?.value.trim();if(!word||!definition){toast('Word and definition are required.');return;}const entry={word,definition,level:document.querySelector('#wordLevel')?.value||'Foundation',sentence:document.querySelector('#wordSentence')?.value.trim()||`Use ${word} in a sentence.`,part:document.querySelector('#wordPart')?.value.trim()||'word',origin:document.querySelector('#wordOrigin')?.value.trim()||'Unknown'};state.customWords=[...(state.customWords||[]).filter(item=>item.word!==word),entry];saveState();runtime.modal=null;toast(`${word.toUpperCase()} saved.`);render();return;}
    if(action==='generate-audio'){runtime.audioBusy=true;runtime.audioMessage='Generation started…';render();try{const result=await services.firebase.buildAudioLibrary();runtime.audioMessage=`${result.assetCount} audio files generated.`;toast(runtime.audioMessage);await hydrateAudioLibrary();}catch(error){runtime.audioMessage=error.message;console.error('Audio generation failed:',error);toast(error.message);}finally{runtime.audioBusy=false;render();}return;}
    if(action==='test-pronunciations'){runtime.audioBusy=true;runtime.audioMessage='Regenerating seven selected words at speed 0.70…';render();try{const result=await services.firebase.regenerateTestPronunciations();runtime.audioMessage=`${result.assetCount} selected pronunciations regenerated for review.`;await hydrateAudioLibrary();toast(runtime.audioMessage);}catch(error){runtime.audioMessage=error.message;console.error('Test pronunciation generation failed:',error);toast(error.message);}finally{runtime.audioBusy=false;render();}return;}
    if(action==='regenerate-primary-pronunciations'){runtime.audioBusy=true;runtime.audioMessage='Regenerating the 60 normal word pronunciations only…';render();try{const result=await services.firebase.regeneratePrimaryPronunciations();runtime.audioMessage=`${result.assetCount} normal pronunciations regenerated. Other audio was unchanged.`;await hydrateAudioLibrary();toast(runtime.audioMessage);}catch(error){runtime.audioMessage=error.message;console.error('Primary pronunciation generation failed:',error);toast(error.message);}finally{runtime.audioBusy=false;render();}return;}
    if(action==='generate-alphabet'){runtime.audioBusy=true;runtime.audioMessage='Alphabet generation started…';render();try{const result=await services.firebase.buildAlphabetLibrary();runtime.audioMessage=`${result.assetCount} alphabet audio files generated.`;await hydrateAudioLibrary();}catch(error){runtime.audioMessage=error.message;console.error('Alphabet generation failed:',error);}finally{runtime.audioBusy=false;render();}return;}
  }

  async function completeOnboarding(demo=false){
    const o=runtime.onboarding;
    const schoolAccount=o.role==='school'?{name:o.schoolName,adminName:o.adminName||o.nickname||'Administrator',country:o.country}:null;
    const learnerName=o.role==='parent'?(o.learnerName||'Ada'):o.role==='school'?(schoolAccount.adminName):(o.nickname||'Ada');
    const p={id:`p-${Date.now()}`,nickname:learnerName,displayName:learnerName,grade:o.role==='school'?'School administrator':o.grade,country:o.country,school:o.role==='school'?o.schoolName:o.school,avatar:o.avatar||learnerName[0].toUpperCase()};
    state={...state,initialized:true,role:o.role,accountOwner:o.role==='parent'?{name:o.guardianName||o.nickname||'Parent',country:o.country}:null,schoolAccount,profiles:[p],activeProfileId:p.id};
    // Demo is intentionally local: access to the product must not wait for Firebase.
    if(demo){
      localStorage.setItem(STORAGE_KEY,JSON.stringify(state));
      navigate('home');
      render();
      return;
    }
    await services.firebase.updateAccountProfile({
      role:o.role,
      displayName:o.role==='parent'?(state.accountOwner?.name||'Parent'):o.role==='school'?(state.schoolAccount?.adminName||'Administrator'):p.nickname,
      schoolName:o.role==='school'?state.schoolAccount?.name:null
    });
    localStorage.setItem(STORAGE_KEY,JSON.stringify(state));
    await services.firebase.save('app-state',state);
    if(o.role!=='school'&&services.firebase.user&&!services.firebase.user.isAnonymous)await services.firebase.bootstrapPlayer(p).catch(error=>toast(error.message));
    warmAudioInBackground();
    if(o.role!=='school')startLiveData();
    navigate(accountLandingRoute());
    render();
  }
  function startLiveData(){
    const user=services.firebase.user;
    if(!user||user.isAnonymous)return;
    runtime.liveUnsubscribe?.();
    const p=profile();
    services.firebase.bootstrapPlayer({...p,displayName:p.nickname}).catch(error=>console.warn('Player setup failed:',error.message));
    runtime.liveUnsubscribe=services.firebase.subscribeLiveData({
      player:value=>{runtime.live.player=value;if(value){state.rank=value.rating||state.rank;}render();},
      leaderboard:value=>{runtime.live.leaderboard=value;render();},
      friendRequests:value=>{runtime.live.friendRequests=value;render();},
      friends:value=>{runtime.live.friends=value;render();},
      teams:value=>{runtime.live.teams=value;render();},
      events:value=>{runtime.live.events=value;render();},
      invitations:value=>{runtime.live.invitations=value;render();},
      assignment:value=>{
        // A saved assignment should complete a matchmaking request, not
        // reopen an old match during an unrelated sign-in or page load.
        const isActivelyQueueing=runtime.competition?.phase==='queue'&&route()==='match';
        if(isActivelyQueueing&&value?.status==='active'&&value.matchId!==runtime.competition?.matchId)subscribeToMatch(value.matchId);
      }
    });
  }
  function recordTrainingAttempt(correct,attempt){
    clearTrainingTimer();const s=runtime.session,e=s.words[s.index],mode=runtime.trainingSetup.mode;
    s.results.push({word:e.word,attempt,correct});
    if(correct){
      s.correct++;s.streak=(s.streak||0)+1;s.bestStreak=Math.max(s.bestStreak||0,s.streak);
      if(mode==='Recall Ladder')s.ladderStage=Math.min(5,(s.ladderStage||0)+1);
      state.reviewWords=state.reviewWords.filter(w=>w!==e.word);
    }else{
      s.streak=0;
      if(mode==='Survival Run')s.lives=Math.max(0,(s.lives||0)-1);
      if(mode==='Recall Ladder')s.ladderStage=Math.max(0,(s.ladderStage||0)-1);
      if(!state.reviewWords.includes(e.word))state.reviewWords.push(e.word);
    }
    s.phase='feedback';s.holdFlash=false;saveState();render();
  }
  function saveLearnerTrainingJourney(session){
    const learner=state.profiles.find(item=>item.id===state.activeProfileId);if(!learner)return;
    const previous=learner.journey||{},attempts=session.results?.length||0,accuracy=attempts?Math.round((session.correct/attempts)*100):0,sessions=(previous.sessions||0)+1;
    learner.journey={...previous,sessions,wordsPractised:(previous.wordsPractised||0)+attempts,bestStreak:Math.max(previous.bestStreak||0,session.bestStreak||session.streak||0),accuracy:Math.round((((previous.accuracy||0)*(sessions-1))+accuracy)/sessions),reviewWords:[...state.reviewWords],lastMode:runtime.trainingSetup.mode,matches:previous.matches||0};
  }
  function finalizeMatch(){const m=runtime.competition;const won=m.playerScore>=m.opponentScore;const rating=won?18:-11;state.rank=Math.max(800,state.rank+rating);state.matches.unshift({id:Date.now(),opponent:m.opponent,result:won?'Won':'Lost',mode:m.mode,score:`${m.playerScore}-${m.opponentScore}`,rating,date:new Date().toISOString()});state.streak=won?state.streak+1:0;const learner=state.profiles.find(item=>item.id===state.activeProfileId);if(learner)learner.journey={...(learner.journey||{}),matches:(learner.journey?.matches||0)+1,bestStreak:Math.max(learner.journey?.bestStreak||0,state.streak)};saveState();}

  document.addEventListener('click',event=>{
    const scrollTarget=event.target.closest('[data-scroll]');if(scrollTarget){document.getElementById(scrollTarget.dataset.scroll)?.scrollIntoView({behavior:state.settings.reducedMotion?'auto':'smooth'});document.querySelector('.landing-header')?.classList.remove('menu-open');return;}
    const nav=event.target.closest('[data-nav]');
    if(nav){
      runtime.modal=null;
      runtime.mobileMenu=false;
      runtime.profileMenu=false;
      if(nav.dataset.nav==='profile')runtime.viewedLearnerId=null;
      navigate(nav.dataset.nav);
      return;
    }
    const role=event.target.closest('[data-onboard-role]');if(role){runtime.onboarding.role=role.dataset.onboardRole;render();return;}
    const av=event.target.closest('[data-avatar]');if(av){runtime.onboarding.avatar=av.dataset.avatar;render();return;}
    const learnerView=event.target.closest('[data-view-learner-id]');if(learnerView){const learner=state.profiles.find(item=>item.id===learnerView.dataset.viewLearnerId);if(!learner){toast('Learner profile not found.');return;}runtime.modal=null;runtime.profileMenu=false;runtime.viewedLearnerId=learner.id;navigate('profile');render();return;}
    const profileChoice=event.target.closest('[data-profile-id]');if(profileChoice){state.activeProfileId=profileChoice.dataset.profileId;runtime.viewedLearnerId=null;saveState();runtime.modal=null;render();return;}
    const mode=event.target.closest('[data-training-mode]');if(mode){selectTrainingMode(mode.dataset.trainingMode);createSession();navigate('train-session');if(['Hear & Spell','Word Flash','Timed Drill'].includes(runtime.trainingSetup.mode))setTimeout(()=>beginTrainingExercise(),firstExerciseDelay(runtime.trainingSetup.mode));return;}
    const assist=event.target.closest('[data-assistance]');if(assist){runtime.trainingSetup.assistance=assist.dataset.assistance;render();return;}
    const letter=event.target.closest('[data-letter]');if(letter&&runtime.session?.phase==='attempt'){enterTrainingLetter(letter.dataset.letter,'typing');return;}
    const piece=event.target.closest('[data-piece]');if(piece&&runtime.session?.phase==='attempt'){[...piece.dataset.piece].forEach(letter=>enterTrainingLetter(letter,'typing'));piece.disabled=true;return;}
    const ml=event.target.closest('[data-match-letter]');if(ml&&runtime.competition?.phase==='playing'){enterCompetitionLetter(ml.dataset.matchLetter);return;}
    const info=event.target.closest('[data-info]');if(info&&!info.disabled){const s=runtime.session,e=s.words[s.index],type=info.dataset.info,unlimited=runtime.trainingSetup.mode==='Hear & Spell'&&type==='repeat';if(!unlimited&&(s.usedRequests||[]).includes(type))return;s.infoType=type;if(!unlimited)s.usedRequests=[...(s.usedRequests||[]),type];render();if(type==='repeat')services.audio.playWord(e);else services.audio.speak({definition:e.definition,sentence:e.sentence,origin:`The origin is ${e.origin}.`,partOfSpeech:`The part of speech is ${e.part}.`}[type]);return;}
    const mi=event.target.closest('[data-match-info]');if(mi){const e=runtime.competition.word;const text={repeat:`The word is ${e.word}.`,definition:e.definition,sentence:e.sentence,origin:`The origin is ${e.origin}.`}[mi.dataset.matchInfo];services.audio.speak(text);document.querySelector('.prompt').textContent=text;return;}
    const tab=event.target.closest('[data-settings-tab]');if(tab){runtime.tab=tab.dataset.settingsTab;render();return;}
    const action=event.target.closest('[data-action]');if(action){if(action.dataset.action==='close-modal'&&event.target!==action&&!event.target.closest('.modal-head button'))return;handleAction(action.dataset.action,action);}
  });

  function setHearSpellFlash(active){
    const s=runtime.session;
    if(!s||runtime.trainingSetup.mode!=='Hear & Spell'||s.phase!=='attempt'||s.holdFlash===active)return;
    s.holdFlash=active;
    render();
  }
  document.addEventListener('pointerdown',event=>{
    const flash=event.target.closest('[data-hold-flash]');
    if(!flash||flash.disabled)return;
    event.preventDefault();
    setHearSpellFlash(true);
  });
  document.addEventListener('pointerup',()=>setHearSpellFlash(false));
  document.addEventListener('pointercancel',()=>setHearSpellFlash(false));
  window.addEventListener('blur',()=>setHearSpellFlash(false));
  document.addEventListener('keydown',event=>{
    if((event.key===' '||event.key==='Enter')&&event.target.closest?.('[data-hold-flash]')&&!event.target.disabled){
      event.preventDefault();setHearSpellFlash(true);
    }
  });
  document.addEventListener('keyup',event=>{
    if((event.key===' '||event.key==='Enter')&&runtime.session?.holdFlash)setHearSpellFlash(false);
  });

  document.addEventListener('change',async event=>{
    if(event.target.id==='manualAlphabetFiles'){
      const files=event.target.files;
      if(!files?.length)return;
      runtime.audioBusy=true;runtime.audioMessage='Uploading the recorded A–Z alphabet…';render();
      try{
        const result=await services.firebase.installManualAlphabet(files);
        runtime.audioMessage=`${result.assetCount} recorded alphabet files installed.`;
        await hydrateAudioLibrary();
        toast(runtime.audioMessage);
      }catch(error){
        runtime.audioMessage=error.message;
        console.error('Recorded alphabet upload failed:',error);
        toast(error.message);
      }finally{runtime.audioBusy=false;render();}
      return;
    }
    if(event.target.id==='trainingLevel'){runtime.trainingSetup.level=event.target.value;render();return;}
    if(event.target.id==='trainingCount'){runtime.trainingSetup.count=Number(event.target.value);render();return;}
    if(event.target.id==='trainingAssistance'){runtime.trainingSetup.assistance=event.target.value;render();return;}
    if(event.target.matches('[data-setting]')){state.settings[event.target.dataset.setting]=event.target.type==='range'?Number(event.target.value):event.target.value;saveState();render();}
    if(event.target.matches('[data-toggle-setting]')){state.settings[event.target.dataset.toggleSetting]=event.target.checked;saveState();if(event.target.dataset.toggleSetting==='reducedMotion')document.documentElement.style.scrollBehavior=event.target.checked?'auto':'';}
  });
  document.addEventListener('submit',async event=>{
    if(event.target.id!=='authForm')return;
    event.preventDefault();
    if(runtime.authBusy)return;
    const email=document.querySelector('#authEmail')?.value.trim();
    const password=document.querySelector('#authPassword')?.value||'';
    const name=document.querySelector('#authName')?.value.trim()||'';
    runtime.authBusy=true;render();
    try{
      if(runtime.authMode==='signup'){
        await services.firebase.createAccount(email,password,{displayName:name,role:'pending'});
        warmAudioInBackground();
        runtime.onboarding.nickname=name;
        runtime.onboarding.avatar=(name[0]||'A').toUpperCase();
        runtime.onboardingStep=0;
        navigate('onboarding');
      }else{
        await services.firebase.login(email,password);
        warmAudioInBackground();
        const [remoteState,accountProfile]=await Promise.all([
          services.firebase.load('app-state'),
          services.firebase.loadAccountProfile()
        ]);
        if(remoteState){
          state=syncAuthenticatedIdentity(remoteState,services.firebase.user);
          if(accountProfile?.role==='parent'){
            const ownerName=state.accountOwner?.name||accountProfile.displayName||services.firebase.user?.displayName||'Parent';
            state={...state,role:'parent',accountOwner:{...(state.accountOwner||{}),name:ownerName,country:state.accountOwner?.country||profile().country||'Nigeria'}};
          }else if(accountProfile?.role==='school'){
            state={...state,role:'school',schoolAccount:{...(state.schoolAccount||{}),name:state.schoolAccount?.name||accountProfile.schoolName||'School',adminName:state.schoolAccount?.adminName||accountProfile.displayName||services.firebase.user?.displayName||'Administrator',country:state.schoolAccount?.country||'Nigeria'}};
          }
          localStorage.setItem(STORAGE_KEY,JSON.stringify(state));
          saveState();
          navigate(accountLandingRoute());
        }else{
          runtime.onboarding.nickname=services.firebase.user?.displayName||'';
          runtime.onboardingStep=0;
          navigate('onboarding');
        }
      }
    }catch(error){
      toast(authErrorMessage(error));
    }finally{
      runtime.authBusy=false;
      render();
    }
  });
  function authErrorMessage(error){
    if(error?.code==='auth/network-request-failed'){
      if(location.protocol==='file:')return 'Firebase sign-in cannot run from a file. Open Alliam through localhost or the deployed website.';
      return 'Firebase Authentication could not be reached. Your general internet connection may still be working.';
    }
    const messages={
      'auth/email-already-in-use':'An account already exists for this email.',
      'auth/invalid-email':'Enter a valid email address.',
      'auth/invalid-credential':'The email or password is incorrect.',
      'auth/user-not-found':'The email or password is incorrect.',
      'auth/wrong-password':'The email or password is incorrect.',
      'auth/weak-password':'Use a password with at least 6 characters.',
      'auth/too-many-requests':'Too many attempts. Please wait and try again.',
      'auth/network-request-failed':'Firebase Authentication could not be reached.'
    };
    return messages[error?.code]||error?.message||'Authentication could not be completed.';
  }
  document.addEventListener('pointerover',event=>{
    const item=event.target.closest('.sidebar-upper .nav button');
    if(!item)return;
    const upper=item.closest('.sidebar-upper');
    const items=[...upper.querySelectorAll('.nav button')];
    upper.style.setProperty('--hover-index',items.indexOf(item));
    upper.classList.add('is-hovering');
  });
  document.addEventListener('pointerout',event=>{
    const upper=event.target.closest('.sidebar-upper');
    if(!upper||upper.contains(event.relatedTarget))return;
    upper.classList.remove('is-hovering');
  });
  document.addEventListener('keydown',event=>{
    const typingTarget=event.target instanceof HTMLInputElement||event.target instanceof HTMLTextAreaElement||event.target instanceof HTMLSelectElement;
    if(typingTarget)return;
    if(event.key==='Backspace'&&route()==='train-session'&&runtime.session?.phase==='attempt'){event.preventDefault();runtime.session.attempt.pop();render();return;}
    if(event.key==='Enter'&&route()==='train-session'&&runtime.session?.phase==='attempt'&&runtime.session.attempt.length){event.preventDefault();const s=runtime.session,attempt=s.attempt.join('');recordTrainingAttempt(attempt===(s.expectedAnswer||s.words[s.index].word),attempt);return;}
    if(/^[a-z]$/i.test(event.key)){
      if(route()==='train-session'&&runtime.session?.phase==='attempt'){enterTrainingLetter(event.key.toLowerCase(),'typing');}
      if(route()==='match'&&runtime.competition?.phase==='playing'){
        const match=runtime.competition;
        if(match.turn==='player'&&match.attempt.length<match.word.word.length){
          match.attempt.push(event.key.toLowerCase());
          render();
        }
      }
    }
  });
  window.addEventListener('hashchange',render);
  window.addEventListener('popstate',render);
  function bindIcons(){const consent=document.querySelector('#consentCheck');if(consent&&runtime.onboarding.role==='student'){consent.checked=true;consent.disabled=true;consent.closest('.switch-row')?.classList.add('consent-locked');}}
  restoreCachedAudioLibrary();
  render();
  if(services.firebase.configured){
    services.firebase.onAuthStateChanged(async user=>{
      if(!user)return;
      warmAudioInBackground();
      try{
        const [remoteState,accountProfile]=await Promise.all([
          services.firebase.load('app-state'),
          services.firebase.loadAccountProfile()
        ]);
        if(remoteState){
          state=syncAuthenticatedIdentity(remoteState,user);
          if(accountProfile?.role==='parent'){
            const ownerName=state.accountOwner?.name||accountProfile.displayName||user.displayName||'Parent';
            state={...state,role:'parent',accountOwner:{...(state.accountOwner||{}),name:ownerName,country:state.accountOwner?.country||profile().country||'Nigeria'}};
          }else if(accountProfile?.role==='school'){
            state={...state,role:'school',schoolAccount:{...(state.schoolAccount||{}),name:state.schoolAccount?.name||accountProfile.schoolName||'School',adminName:state.schoolAccount?.adminName||accountProfile.displayName||user.displayName||'Administrator',country:state.schoolAccount?.country||'Nigeria'}};
          }
          localStorage.setItem(STORAGE_KEY,JSON.stringify(state));
          saveState();
        }
        startLiveData();
        render();
      }catch(error){console.warn('Firebase startup failed:',error.message);}
    });
  }
})();
