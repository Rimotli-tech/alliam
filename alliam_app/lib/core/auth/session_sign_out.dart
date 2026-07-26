import 'package:firebase_auth/firebase_auth.dart';

Future<void> signOutAlliamSession() async {
  final auth = FirebaseAuth.instance;
  final user = auth.currentUser;
  if (user?.isAnonymous == true) {
    await user!.delete();
    return;
  }
  await auth.signOut();
}
