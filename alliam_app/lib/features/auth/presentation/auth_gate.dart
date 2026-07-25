import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../home/presentation/home_page.dart';
import '../data/account_repository.dart';
import '../domain/account_session.dart';
import 'onboarding_page.dart';
import 'sign_in_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  int _revision = 0;

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
        if (user == null) return const SignInPage();
        return FutureBuilder<AccountSession>(
          key: ValueKey('${user.uid}-$_revision'),
          future: AccountRepository(FirebaseFirestore.instance).load(user),
          builder: (context, accountSnapshot) {
            if (accountSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
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
            return const HomePage();
          },
        );
      },
    );
  }
}
