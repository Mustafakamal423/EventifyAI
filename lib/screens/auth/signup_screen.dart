import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'auth_widgets.dart';
import 'login_screen.dart';

/// UC01 - Create account (design: mobile-02). The user picks Attendee or
/// Organizer; the server hashes the password with bcrypt and returns a JWT.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  String _role = 'attendee';
  Map<String, String> _errors = {};

  Future<void> _submit() async {
    setState(() => _errors = {});
    // Phone numbers are Ethiopian: the +251 prefix is shown next to the field
    var phone = _phone.text.replaceAll(' ', '');
    if (phone.startsWith('0')) phone = phone.substring(1);
    if (phone.isNotEmpty && !phone.startsWith('+')) phone = '+251$phone';
    try {
      await context.read<Session>().register(fullName: _name.text, email: _email.text, phone: phone, password: _password.text, role: _role);
    } on ApiException catch (e) {
      setState(() => _errors = e.fieldErrors);
      if (e.fieldErrors.isEmpty) rethrow;
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _roleCard(String role, String title, String sub) {
    final selected = _role == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? C.ink : C.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? C.ink : C.line, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: T.body(17, weight: FontWeight.w700, color: selected ? C.bg : C.ink),
              ),
              const SizedBox(height: 4),
              Text(sub, style: T.body(14, color: selected ? C.darkMuted : C.muted)),
            ],
          ),
        ),
      ),
    );
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
              const SizedBox(height: 24),
              Text('Create your account', style: T.display(36)),
              const SizedBox(height: 8),
              Text("Pick how you'll use Eventify. You can't switch later without admin help.", style: T.body(16, color: C.muted)),
              const SizedBox(height: 22),
              Row(
                children: [
                  _roleCard('attendee', 'Attendee', 'Buy tickets, meet people'),
                  const SizedBox(width: 12),
                  _roleCard('organizer', 'Organizer', 'Run events, scan tickets'),
                ],
              ),
              if (_errors['role'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(_errors['role']!, style: T.body(13, color: C.danger)),
                ),
              const SizedBox(height: 20),
              LabeledField(
                label: 'Full name',
                controller: _name,
                hint: 'Meron Assefa',
                error: _errors['full_name'],
                autofill: const [AutofillHints.name],
              ),
              LabeledField(
                label: 'Email',
                controller: _email,
                hint: 'you@example.com',
                keyboard: TextInputType.emailAddress,
                error: _errors['email'],
                autofill: const [AutofillHints.email],
              ),
              LabeledField(
                label: 'Phone number',
                controller: _phone,
                hint: '9X XXX XXXX',
                keyboard: TextInputType.phone,
                error: _errors['phone_number'],
                prefix: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
                  child: Text('+251', style: T.body(16, color: C.muted)),
                ),
              ),
              LabeledField(label: 'Password', controller: _password, hint: 'At least 8 characters', obscure: true, error: _errors['password']),
              const SizedBox(height: 12),
              BusyButton(label: 'Create account', onPressed: _submit),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account?', style: T.body(15, color: C.muted)),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text('Log in'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
