import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_gate.dart';
import '../features/compete/presentation/compete_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/profile/presentation/profile_page.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/train/presentation/train_page.dart';
import '../features/train/presentation/training_session_page.dart';
import '../features/train/domain/training_mode.dart';

final alliamRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final signedIn = FirebaseAuth.instance.currentUser != null;
    if (!signedIn && state.uri.path != '/') return '/';
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AuthGate()),
    GoRoute(path: '/home', builder: (context, state) => const HomePage()),
    GoRoute(path: '/train', builder: (context, state) => const TrainPage()),
    GoRoute(
      path: '/train/session/:mode',
      builder: (context, state) => TrainingSessionPage(
        mode: TrainingModeDetails.fromSlug(state.pathParameters['mode'] ?? ''),
      ),
    ),
    GoRoute(path: '/compete', builder: (context, state) => const CompetePage()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
    GoRoute(
      path: '/profile/learner/:id',
      builder: (context, state) =>
          LearnerProfilePage(learnerId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);
