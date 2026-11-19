import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'auth_widgets.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

/// UC02 - Log in (design: mobile-03). On success the session changes and
/// RoleGate (main.dart) opens the attendee app or the organizer's door tools.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  Map<String, String> _errors = {};

  Future<void> _submit() async {
    setState(() => _errors = {});
    try {
      await context.read<Session>().login(_email.text, _password.text);
    } on ApiException catch (e) {
      setState(() => _errors = e.fieldErrors);
      if (e.fieldErrors.isEmpty) rethrow; // shown as a toast by BusyButton
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BackCircle(),
                const SizedBox(height: 28),
                Text('Welcome back', style: T.display(38)),
                const SizedBox(height: 8),
                Text('Log in to see your tickets and the people at your events.', style: T.body(17, color: C.muted)),
                const SizedBox(height: 28),
                LabeledField(
                  label: 'Email',
                  controller: _email,
                  hint: 'you@example.com',
                  keyboard: TextInputType.emailAddress,
                  error: _errors['email'],
                  action: TextInputAction.next,
                  autofill: const [AutofillHints.email],
                ),
                LabeledField(
                  label: 'Password',
                  controller: _password,
                  obscure: true,
                  error: _errors['password'],
                  action: TextInputAction.done,
                  autofill: const [AutofillHints.password],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 16),
                BusyButton(label: 'Log in', onPressed: _submit),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('New to Eventify?', style: T.body(15, color: C.muted)),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SignupScreen())),
                      child: const Text('Create account'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
