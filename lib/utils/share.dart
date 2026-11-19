import 'package:share_plus/share_plus.dart';

import '../api/models.dart';
import '../config.dart';
import 'format.dart';

/// Share an event to Telegram, WhatsApp, Facebook, etc. through the phone's
/// own share sheet. The link opens the event's web page, whose link-preview
/// (Open Graph) tags show the title, date and banner in the chat.
/// The message matches the web app's share text (public/js/core.js).
Future<void> shareEvent(EventItem e) {
  final venue = e.isOnline ? '' : (e.venueName != null ? ' at ${e.venueName}' : '');
  final text = '${e.title} · ${Fmt.dateTime(e.start)}$venue. Get your ticket on Eventify AI:\n${AppConfig.eventLink(e.id)}';
  return SharePlus.instance.share(ShareParams(text: text, subject: e.title));
}
