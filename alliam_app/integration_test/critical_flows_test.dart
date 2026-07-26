import 'package:alliam_app/features/auth/data/account_repository.dart';
import 'package:alliam_app/features/auth/domain/account_session.dart';
import 'package:alliam_app/features/compete/data/competition_service.dart';
import 'package:alliam_app/features/train/data/training_progress_repository.dart';
import 'package:alliam_app/features/train/domain/training_mode.dart';
import 'package:alliam_app/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const emulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: 'localhost',
  );

  late FirebaseApp primary;
  late FirebaseApp opponent;
  late FirebaseAuth primaryAuth;
  late FirebaseAuth opponentAuth;
  late FirebaseFirestore primaryStore;
  late FirebaseFirestore opponentStore;

  setUpAll(() async {
    primary = await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    opponent = await Firebase.initializeApp(
      name: 'integration-opponent',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    primaryAuth = FirebaseAuth.instanceFor(app: primary);
    opponentAuth = FirebaseAuth.instanceFor(app: opponent);
    primaryStore = FirebaseFirestore.instanceFor(app: primary);
    opponentStore = FirebaseFirestore.instanceFor(app: opponent);
    primaryAuth.useAuthEmulator(emulatorHost, 9099);
    opponentAuth.useAuthEmulator(emulatorHost, 9099);
    primaryStore.useFirestoreEmulator(emulatorHost, 8080);
    opponentStore.useFirestoreEmulator(emulatorHost, 8080);
  });

  testWidgets('auth, parent onboarding and learner switching', (_) async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final credential = await primaryAuth.createUserWithEmailAndPassword(
      email: 'parent-$stamp@alliam.test',
      password: 'Test-pass-123!',
    );
    final user = credential.user!;
    final repository = AccountRepository(primaryStore);
    await repository.completeParent(
      user: user,
      parentName: 'Amina Parent',
      country: 'Nigeria',
      learnerName: 'Liam',
      grade: 'Grade 1',
      school: 'Alliam Test School',
    );
    var session = await repository.load(user);
    expect(session.role, AccountRole.parent);
    expect(session.activeLearner?.name, 'Liam');

    final second = await repository.addLearner(
      user: user,
      session: session,
      name: 'Kandi',
      grade: 'Grade 2',
      country: 'Nigeria',
      school: 'Alliam Test School',
    );
    await repository.setActiveLearner(user, second.id);
    session = await repository.load(user);
    expect(session.learners, hasLength(2));
    expect(session.activeLearner?.name, 'Kandi');
  });

  testWidgets('training completion writes normalized learner progress', (
    _,
  ) async {
    final user = primaryAuth.currentUser!;
    final session = await AccountRepository(primaryStore).load(user);
    final learner = session.activeLearner!;
    await TrainingProgressRepository(primaryStore, primaryAuth).recordSession(
      mode: TrainingMode.hearAndSpell,
      correct: 4,
      attempted: 5,
      incorrectWords: {'rhythm'},
    );
    final sessions = await primaryStore
        .collection('accounts/${user.uid}/learners/${learner.id}/sessions')
        .get();
    expect(sessions.docs, isNotEmpty);
    expect(sessions.docs.last.data()['attempted'], 5);
  });

  testWidgets('two players match, cancel and forfeit authoritatively', (
    _,
  ) async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final first = primaryAuth.currentUser!;
    final secondCredential = await opponentAuth.createUserWithEmailAndPassword(
      email: 'opponent-$stamp@alliam.test',
      password: 'Test-pass-123!',
    );
    final second = secondCredential.user!;
    await AccountRepository(opponentStore).completeStudent(
      user: second,
      name: 'Tobi',
      grade: 'Grade 1',
      country: 'Nigeria',
      school: 'Alliam Test School',
    );

    final firstFunctions = FirebaseFunctions.instanceFor(
      app: primary,
      region: 'europe-west1',
    )..useFunctionsEmulator(emulatorHost, 5001);
    final secondFunctions = FirebaseFunctions.instanceFor(
      app: opponent,
      region: 'europe-west1',
    )..useFunctionsEmulator(emulatorHost, 5001);
    final firstService = CompetitionService(
      auth: primaryAuth,
      firestore: primaryStore,
      functions: firstFunctions,
    );
    final secondService = CompetitionService(
      auth: opponentAuth,
      firestore: opponentStore,
      functions: secondFunctions,
    );
    await firstService.bootstrap(
      await AccountRepository(primaryStore).load(first),
    );
    await secondService.bootstrap(
      await AccountRepository(opponentStore).load(second),
    );

    final roomCode = await firstService.createPrivateRoom();
    await firstService.cancelPrivateRoom(roomCode);
    final cancelledRoom = await primaryStore
        .doc('privateRooms/$roomCode')
        .get();
    expect(cancelledRoom.data()?['status'], 'cancelled');

    final cancellationMode = 'Cancel $stamp';
    await firstService.joinQueue(cancellationMode);
    await firstService.cancelQueue();
    expect(
      (await primaryStore.doc('matchQueue/${first.uid}').get()).exists,
      isFalse,
    );

    final mode = 'Integration $stamp';
    final waiting = await firstService.joinQueue(mode);
    expect(waiting.matchId, isNull);
    final matched = await secondService.joinQueue(mode);
    final matchId = matched.matchId!;
    await firstService.forfeit(matchId);

    final match = await primaryStore.doc('matches/$matchId').get();
    expect(match.data()?['status'], 'completed');
    expect(match.data()?['completionReason'], 'forfeit');
    expect(match.data()?['forfeitedBy'], first.uid);
    expect(match.data()?['winnerUid'], second.uid);
  });

  testWidgets('legacy student, parent and school accounts migrate safely', (
    _,
  ) async {
    final stamp = DateTime.now().microsecondsSinceEpoch;

    Future<({AccountSession session, String uid})> seedAndLoad({
      required String label,
      required String legacyRole,
      required String displayName,
      required Map<String, dynamic> legacyValue,
    }) async {
      final credential = await primaryAuth.createUserWithEmailAndPassword(
        email: 'legacy-$label-$stamp@alliam.test',
        password: 'Test-pass-123!',
      );
      final user = credential.user!;
      await primaryStore.doc('accounts/${user.uid}').set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName,
        'role': 'pending',
      });
      await primaryStore.doc('accounts/${user.uid}/data/app-state').set({
        'value': {
          'initialized': true,
          'accountType': legacyRole,
          ...legacyValue,
        },
      });
      return (
        session: await AccountRepository(primaryStore).load(user),
        uid: user.uid,
      );
    }

    final student = await seedAndLoad(
      label: 'student',
      legacyRole: 'student',
      displayName: 'Legacy Student',
      legacyValue: {
        'activeProfileId': 'legacy-student',
        'profiles': [
          {
            'id': 'legacy-student',
            'nickname': 'Sade',
            'grade': 'Grade 2',
            'country': 'Nigeria',
            'school': 'Old School',
            'avatar': 'S',
          },
        ],
      },
    );
    expect(student.session.role, AccountRole.student);
    expect(student.session.ownerName, 'Legacy Student');
    expect(student.session.activeLearner?.name, 'Sade');

    final parent = await seedAndLoad(
      label: 'parent',
      legacyRole: 'parent',
      displayName: 'Outdated Parent Name',
      legacyValue: {
        'accountOwner': {'name': 'Freda Parent', 'country': 'Nigeria'},
        'activeProfileId': 'legacy-child',
        'profiles': [
          {
            'id': 'legacy-child',
            'nickname': 'Liam',
            'grade': 'Grade 1',
            'country': 'Nigeria',
            'school': 'Old School',
            'avatar': 'L',
          },
        ],
      },
    );
    expect(parent.session.role, AccountRole.parent);
    expect(parent.session.ownerName, 'Freda Parent');
    expect(parent.session.activeLearner?.name, 'Liam');

    final school = await seedAndLoad(
      label: 'school',
      legacyRole: 'school',
      displayName: 'Outdated Admin Name',
      legacyValue: {
        'schoolAccount': {
          'name': 'Alliam Academy',
          'adminName': 'Amina Admin',
          'country': 'Nigeria',
        },
        'profiles': <Map<String, dynamic>>[],
      },
    );
    expect(school.session.role, AccountRole.school);
    expect(school.session.ownerName, 'Amina Admin');
    expect(school.session.schoolName, 'Alliam Academy');

    for (final session in [student, parent, school]) {
      expect(session.session.onboardingComplete, isTrue);
    }

    await primaryAuth.signInWithEmailAndPassword(
      email: 'legacy-parent-$stamp@alliam.test',
      password: 'Test-pass-123!',
    );
    final migratedParent = await primaryStore
        .doc('accounts/${parent.uid}')
        .get();
    expect(migratedParent.data()?['schemaVersion'], 2);
    expect(migratedParent.data()?['role'], 'parent');
    final normalizedLearner = await primaryStore
        .doc('accounts/${parent.uid}/learners/legacy-child')
        .get();
    expect(normalizedLearner.data()?['nickname'], 'Liam');
  });
}
