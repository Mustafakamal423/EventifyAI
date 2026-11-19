import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'auth_widgets.dart';

/// Forgot password: the server emails a reset link (BR-14). The link opens the
/// reset page on the web, so the new password is set there.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _email = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BackCircle(),
              const SizedBox(height: 28),
              Text('Reset your password', style: T.display(36)),
              const SizedBox(height: 8),
              Text(
                _sent
                    ? 'If an account exists for ${_email.text.trim()}, a reset link is on its way. Open it on this phone to choose a new password.'
                    : "Enter your account's email and we'll send you a link to choose a new password.",
                style: T.body(16, color: C.muted),
              ),
              const SizedBox(height: 26),
              if (!_sent) ...[
                LabeledField(label: 'Email', controller: _email, hint: 'you@example.com', keyboard: TextInputType.emailAddress),
                BusyButton(
                  label: 'Send reset link',
                  onPressed: () async {
                    await api.post('/auth/forgot-password', {'email': _email.text.trim()});
                    setState(() => _sent = true);
                  },
                ),
              ] else
                OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back to log in')),
            ],
          ),
        ),
      ),
    );
  }
}
