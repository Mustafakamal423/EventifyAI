import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../api/api_client.dart';
import '../../api/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../auth/auth_widgets.dart';

/// UC03 - Networking profile setup / edit (design: mobile-04).
/// Skills, interests and goals feed the AI matchmaking (FR-10), so a new
/// attendee is sent here right after signing up ([onboarding] = true).
class ProfileEditScreen extends StatefulWidget {
  final bool onboarding;
  const ProfileEditScreen({super.key, this.onboarding = false});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  // Same suggestions as the web form (public/js/pages/profile-form.js)
  static const suggested = [
    'Flutter', 'Fintech', 'Mobile payments', 'Product design', 'Machine learning', 'AgriTech', 'Startups', 'AI', //
    'Python', 'UX research', 'Marketing', 'HealthTech', 'Cloud', 'Data analysis', 'Investing',
  ];
  static const goalOptions = ['Co-founder', 'Investors', 'Hiring', 'Mentorship', 'Clients'];
  // Topics (rather than abilities) are stored as interests; they also drive
  // the "Picked for you" event recommendations.
  static const topics = {'Fintech', 'AgriTech', 'Startups', 'AI', 'HealthTech', 'Investing', 'Mobile payments', 'Cloud', 'Marketing'};

  final _job = TextEditingController();
  final _company = TextEditingController();
  final _bio = TextEditingController();
  final _linkedin = TextEditingController();
  Profile? _profile;
  List<String> _allTags = [...suggested];
  final Set<String> _selected = {};
  final Set<String> _goals = {};
  Map<String, String> _errors = {};
  bool _uploading = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_job, _company, _bio, _linkedin]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = Profile.fromJson(await api.get('/profile'));
      setState(() {
        _profile = p;
        _loadError = null;
        _job.text = p.jobTitle ?? '';
        _company.text = p.company ?? '';
        _bio.text = p.bio ?? '';
        _linkedin.text = p.linkedinUrl ?? '';
        final mine = {...p.skills, ...p.interests};
        _allTags = [...mine, ...suggested.where((s) => !mine.contains(s))];
        _selected.addAll(mine);
        _goals.addAll(p.goals);
      });
    } catch (e) {
      setState(() => _loadError = e);
    }
  }

  Future<void> _pickPhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 85);
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      await api.upload('/profile/photo', 'photo', File(file.path));
      await _load();
      if (mounted) toast(context, 'Photo updated');
    } catch (e) {
      if (mounted) toast(context, e);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _addTag() async {
    final controller = TextEditingController();
    final tag = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add a skill or interest'),
        content: TextField(controller: controller, autofocus: true, textCapitalization: TextCapitalization.sentences, maxLength: 40),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    if (tag == null || tag.isEmpty) return;
    setState(() {
      if (!_allTags.contains(tag)) _allTags.add(tag);
      _selected.add(tag);
    });
  }

  Future<void> _save() async {
    setState(() => _errors = {});
    final chosen = _allTags.where(_selected.contains).toList();
    final wasInterest = _profile?.interests.toSet() ?? {};
    bool isInterest(String t) => wasInterest.contains(t) || topics.contains(t);
    try {
      await api.patch('/profile', {
        'job_title': _job.text.trim(),
        'company': _company.text.trim(),
        'bio': _bio.text.trim(),
        'linkedin_url': _linkedin.text.trim(),
        'skills': chosen.where((t) => !isInterest(t)).toList(),
        'interests': chosen.where(isInterest).toList(),
        'goals': _goals.toList(),
      });
      if (!mounted) return;
      toast(context, 'Profile saved');
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _errors = e.fieldErrors);
      if (e.fieldErrors.isEmpty) rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _profile;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.onboarding,
        title: widget.onboarding ? Text('STEP 2 OF 2', style: T.eyebrow()) : const Text('Edit profile'),
        actions: [if (widget.onboarding) TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Skip for now'))],
      ),
      body: p == null
          ? (_loadError != null ? ErrorView(error: _loadError, onRetry: _load) : const Center(child: CircularProgressIndicator(color: C.accent)))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                if (widget.onboarding) ...[
                  Text('Tell the room who you are', style: T.display(32)),
                  const SizedBox(height: 8),
                  Text('Shown on your card in the Digital Room and used by AI matchmaking.', style: T.body(16, color: C.muted)),
                  const SizedBox(height: 20),
                ],
                InkWell(
                  onTap: _uploading ? null : _pickPhoto,
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: C.surface,
                          border: Border.all(color: C.line, width: 2),
                        ),
                        child: _uploading
                            ? const Padding(
                                padding: EdgeInsets.all(28),
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: C.accent),
                              )
                            : p.photo != null
                            ? Avatar(name: p.fullName, photo: p.photo, size: 84)
                            : const Icon(Icons.add, size: 32, color: C.muted),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.photo != null ? 'Change photo' : 'Add a photo', style: T.body(18, weight: FontWeight.w700)),
                            Text('People find you faster in a crowd', style: T.body(15, color: C.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: LabeledField(label: 'Job title', controller: _job, hint: 'Flutter Developer', error: _errors['job_title']),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LabeledField(label: 'Company', controller: _company, hint: 'Freelance', error: _errors['company']),
                    ),
                  ],
                ),
                LabeledField(
                  label: 'Short bio',
                  controller: _bio,
                  hint: 'What you work on, in a sentence or two',
                  maxLines: 3,
                  error: _errors['bio'],
                ),
                Text('Skills & interests', style: T.body(15, weight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in _allTags)
                      FilterChip(
                        label: Text(t),
                        selected: _selected.contains(t),
                        showCheckmark: false,
                        selectedColor: C.ink,
                        backgroundColor: C.surface,
                        side: const BorderSide(color: C.line),
                        shape: const StadiumBorder(),
                        labelStyle: T.body(15, color: _selected.contains(t) ? C.bg : C.ink),
                        onSelected: (on) => setState(() => on ? _selected.add(t) : _selected.remove(t)),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      backgroundColor: C.bg,
                      side: const BorderSide(color: C.line),
                      shape: const StadiumBorder(),
                      onPressed: _addTag,
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text("At events, I'm looking for", style: T.body(15, weight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final g in goalOptions)
                      FilterChip(
                        label: Text(g),
                        selected: _goals.contains(g),
                        showCheckmark: false,
                        selectedColor: C.green,
                        backgroundColor: C.surface,
                        side: const BorderSide(color: C.line),
                        shape: const StadiumBorder(),
                        labelStyle: T.body(15, color: _goals.contains(g) ? C.bg : C.ink),
                        onSelected: (on) => setState(() => on ? _goals.add(g) : _goals.remove(g)),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                LabeledField(
                  label: 'LinkedIn URL (optional)',
                  controller: _linkedin,
                  hint: 'linkedin.com/in/...',
                  keyboard: TextInputType.url,
                  error: _errors['linkedin_url'],
                ),
                const SizedBox(height: 8),
                BusyButton(label: widget.onboarding ? 'Save and explore events' : 'Save profile', onPressed: _save),
              ],
            ),
    );
  }
}
