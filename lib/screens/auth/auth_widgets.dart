import 'package:flutter/material.dart';

import '../../theme.dart';

/// A labelled text field used on the auth and profile forms. [error] shows the
/// server's message for this field (from the validate middleware).
class LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? error;
  final bool obscure;
  final TextInputType? keyboard;
  final Widget? prefix;
  final int maxLines;
  final TextInputAction? action;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofill;

  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.error,
    this.obscure = false,
    this.keyboard,
    this.prefix,
    this.maxLines = 1,
    this.action,
    this.onSubmitted,
    this.autofill,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: T.body(15, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboard,
            maxLines: maxLines,
            textInputAction: action,
            onSubmitted: onSubmitted,
            autofillHints: autofill,
            style: T.body(16),
            decoration: InputDecoration(hintText: hint, errorText: error, prefixIcon: prefix),
          ),
        ],
      ),
    );
  }
}

/// Round back button used at the top of the auth screens.
class BackCircle extends StatelessWidget {
  const BackCircle({super.key});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Material(
      color: C.surface,
      shape: const CircleBorder(side: BorderSide(color: C.line)),
      child: IconButton(icon: const Icon(Icons.chevron_left), tooltip: 'Back', onPressed: () => Navigator.of(context).maybePop()),
    ),
  );
}
