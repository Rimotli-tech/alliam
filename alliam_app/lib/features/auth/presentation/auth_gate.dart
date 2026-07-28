import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/admin/admin_access.dart';
import '../../../core/auth/session_sign_out.dart';
import '../data/account_repository.dart';
import '../domain/account_session.dart';
import 'onboarding_page.dart';
import 'sign_in_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.openSignUp = false});

  final bool openSignUp;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  int _revision = 0;

  Future<AccountSession> _loadAccount(User user) async {
    if (user.email?.toLowerCase() == AdminAccess.bootstrapEmail) {
      await AdminAccess.ensureAdmin();
    }
    return AccountRepository(FirebaseFirestore.instance).load(user);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        if (user == null) return SignInPage(openSignUp: widget.openSignUp);
        return FutureBuilder<AccountSession>(
          key: ValueKey('${user.uid}-$_revision'),
          future: _loadAccount(user),
          builder: (context, accountSnapshot) {
            if (accountSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (accountSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sync_problem_rounded, size: 42),
                          const SizedBox(height: 16),
                          Text(
                            'Account setup was interrupted',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Resume setup to safely complete the missing account records.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () => setState(() => _revision++),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Resume account setup'),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () async {
                              await signOutAlliamSession();
                              if (context.mounted) context.go('/');
                            },
                            child: const Text('Sign out'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }
            final session =
                accountSnapshot.data ??
                AccountSession.fallback(user.email ?? 'Speller');
            if (!session.onboardingComplete) {
              return OnboardingPage(
                user: user,
                onComplete: () => setState(() => _revision++),
              );
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.go(session.entryLocation);
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        );
      },
    );
  }
}
