import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/brand.dart';
import '../../widgets/common.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// First screen for logged-out users (design: mobile-01 Welcome).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.ink,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const BrandMark(size: 26, onDark: true),
                    const SizedBox(height: 48),
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(text: 'Walk in with a ticket. Walk out with '),
                          TextSpan(
                            text: 'the right people.',
                            style: T.display(44, color: C.gold),
                          ),
                        ],
                      ),
                      style: T.display(44, color: C.bg),
                    ),
                    const SizedBox(height: 18),
                    Text('Tickets, check-in and AI networking for events across Ethiopia.', style: T.body(17, color: C.darkMuted)),
                    const SizedBox(height: 32),
                    // Example of what the AI matching does once you're checked in
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: C.dark2,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: C.darkLine),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const SizedBox(
                                width: 78,
                                height: 44,
                                child: Stack(
                                  children: [
                                    Avatar(name: 'Meron Assefa', size: 44),
                                    Positioned(left: 34, child: Avatar(name: 'Hanna Girma', size: 44)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'You and Hanna Girma',
                                      style: T.body(16, color: C.bg, weight: FontWeight.w700),
                                    ),
                                    Text('Both in fintech · both at Hall A', style: T.body(14, color: C.darkMuted)),
                                  ],
                                ),
                              ),
                              const Pill('88%', bg: C.green, fg: C.bg),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text('Your AI match is checked in. Say hi before the panel starts.', style: T.body(15, color: C.darkMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const TibebStrip(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                children: [
                  FilledButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SignupScreen())),
                    child: const Text('Create account'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: C.bg,
                      side: const BorderSide(color: C.darkLine, width: 1.5),
                    ),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text('I already have an account'),
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
