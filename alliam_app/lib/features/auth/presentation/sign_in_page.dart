import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/alliam_colors.dart';
import '../../../core/widgets/alliam_background.dart';
import '../../../core/widgets/alliam_logo.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key, this.openSignUp = false});

  final bool openSignUp;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late bool _creating;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _creating = widget.openSignUp;
  }

  @override
  void didUpdateWidget(covariant SignInPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.openSignUp != widget.openSignUp) {
      _creating = widget.openSignUp;
      _error = null;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || !_email.text.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (_password.text.length < 6) {
      setState(() => _error = 'Use a password with at least six characters.');
      return;
    }
    if (_creating && _name.text.trim().isEmpty) {
      setState(() => _error = 'Enter your name.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_creating) {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _email.text.trim(),
              password: _password.text,
            );
        await credential.user?.updateDisplayName(_name.text.trim());
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      setState(() => _error = _message(error.code));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      await FirebaseAuth.instance.signInWithPopup(provider);
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _message(error.code));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _email.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('We’ll send a secure reset link to your email.'),
            const SizedBox(height: 18),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Send link'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (email == null || email.isEmpty) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent.')),
        );
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _message(error.code));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth <= 780;
          final brand = _AuthBrand(creating: _creating, compact: compact);
          final panel = Expanded(
            child: AlliamBackground(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(compact ? 24 : 38),
                  child: _AuthCard(
                    creating: _creating,
                    busy: _busy,
                    error: _error,
                    name: _name,
                    email: _email,
                    password: _password,
                    onSubmit: _submit,
                    onGoogleSignIn: _googleSignIn,
                    onForgotPassword: _forgotPassword,
                    onToggle: () => setState(() {
                      _creating = !_creating;
                      _error = null;
                    }),
                  ),
                ),
              ),
            ),
          );
          if (compact) {
            return Column(
              children: [
                SizedBox(height: 250, child: brand),
                panel,
              ],
            );
          }
          return Row(
            children: [
              SizedBox(width: constraints.maxWidth * 0.42, child: brand),
              panel,
            ],
          );
        },
      ),
    );
  }

  String _message(String code) {
    return switch (code) {
      'invalid-credential' => 'The email or password is incorrect.',
      'email-already-in-use' => 'An account already uses this email.',
      'weak-password' => 'Use a password with at least six characters.',
      'network-request-failed' => 'Unable to connect. Please try again.',
      'operation-not-allowed' => 'Google sign-in is not enabled yet.',
      'popup-closed-by-user' => 'Google sign-in was cancelled.',
      'popup-blocked' => 'Allow pop-ups to continue with Google.',
      'account-exists-with-different-credential' =>
        'That email already uses another sign-in method.',
      'user-not-found' => 'No account uses that email address.',
      'invalid-email' => 'Enter a valid email address.',
      'too-many-requests' => 'Please wait a moment before trying again.',
      _ => 'We could not complete that request. Please try again.',
    };
  }
}

class _AuthBrand extends StatelessWidget {
  const _AuthBrand({required this.creating, required this.compact});

  final bool creating;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AlliamColors.coral, Color(0xFFFFA046)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              width: 360,
              height: 360,
              right: -170,
              top: -100,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              width: 240,
              height: 240,
              left: -110,
              bottom: -95,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(compact ? 28 : 52),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AlliamLogo(width: 112, color: Colors.white),
                  const Spacer(),
                  if (!compact)
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Icon(
                        creating
                            ? Icons.person_outline_rounded
                            : Icons.lock_outline_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  if (!compact) const SizedBox(height: 24),
                  Text(
                    creating ? 'Ready to rise?' : 'Welcome back',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: Colors.white,
                      fontSize: compact ? 38 : 58,
                      height: 1.02,
                      letterSpacing: -2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    creating
                        ? 'Create one secure account for training, competitions, and progress.'
                        : 'Continue your spelling journey.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 17,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.creating,
    required this.busy,
    required this.error,
    required this.name,
    required this.email,
    required this.password,
    required this.onSubmit,
    required this.onGoogleSignIn,
    required this.onForgotPassword,
    required this.onToggle,
  });

  final bool creating;
  final bool busy;
  final String? error;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController password;
  final VoidCallback onSubmit;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onForgotPassword;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: AlliamColors.surface,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: AlliamColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55E1DCD8),
            blurRadius: 12.5,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.chevron_left_rounded, size: 17),
              label: const Text('Home'),
              style: TextButton.styleFrom(
                foregroundColor: AlliamColors.text,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            creating ? 'CREATE ACCOUNT' : 'SIGN IN',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AlliamColors.coral,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            creating ? 'Join Alliam' : 'Your account',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AlliamColors.coral,
              fontSize: 34,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 21),
          if (creating) ...[
            _LabeledField(
              label: 'Name',
              controller: name,
              hint: 'Ada',
              autofillHints: const [AutofillHints.name],
            ),
            const SizedBox(height: 17),
          ],
          _LabeledField(
            label: 'Email',
            controller: email,
            hint: 'name@example.com',
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 17),
          _LabeledField(
            label: 'Password',
            controller: password,
            hint: 'At least 6 characters',
            obscureText: true,
            autofillHints: [
              creating ? AutofillHints.newPassword : AutofillHints.password,
            ],
            onSubmitted: onSubmit,
          ),
          if (!creating) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: busy ? null : onForgotPassword,
                child: const Text('Forgot password?'),
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 13),
            Text(error!, style: const TextStyle(color: AlliamColors.error)),
          ],
          const SizedBox(height: 17),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: busy ? null : onSubmit,
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 22),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    busy
                        ? 'Please wait…'
                        : creating
                        ? 'Create account'
                        : 'Sign in',
                  ),
                  const SizedBox(width: 9),
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 17),
          TextButton(
            onPressed: busy ? null : onToggle,
            style: TextButton.styleFrom(foregroundColor: AlliamColors.coral),
            child: Text(
              creating
                  ? 'Already have an account? Sign in'
                  : 'New to Alliam? Create an account',
            ),
          ),
          const SizedBox(height: 17),
          const Row(
            children: [
              Expanded(child: Divider(color: AlliamColors.line)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('or', style: TextStyle(fontSize: 12)),
              ),
              Expanded(child: Divider(color: AlliamColors.line)),
            ],
          ),
          const SizedBox(height: 17),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: busy ? null : onGoogleSignIn,
              icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
              label: const Text('Continue with Google'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AlliamColors.text,
                backgroundColor: AlliamColors.surfaceStrong,
                side: const BorderSide(color: AlliamColors.line),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.autofillHints,
    this.obscureText = false,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AlliamColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: 52,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            autofillHints: autofillHints,
            obscureText: obscureText,
            onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
            decoration: InputDecoration(hintText: hint),
          ),
        ),
      ],
    );
  }
}
