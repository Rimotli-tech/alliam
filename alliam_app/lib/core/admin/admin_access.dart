import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract final class AdminAccess {
  static const bootstrapEmail = 'rimotli.tech@gmail.com';

  static Future<bool> ensureAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    var token = await user.getIdTokenResult();
    if (token.claims?['admin'] == true) return true;
    if (user.email?.toLowerCase() != bootstrapEmail) return false;
    await FirebaseFunctions.instanceFor(
      region: 'europe-west1',
    ).httpsCallable('bootstrapAdminRole').call<void>();
    token = await user.getIdTokenResult(true);
    return token.claims?['admin'] == true;
  }
}
