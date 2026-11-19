/// App-wide settings.
///
/// The mobile app talks to the same REST API as the web app (SDD 3.5.1), so the
/// only thing it needs to know is where the server lives. Pick it at build time:
///
///   flutter run                                              -> live server
///   flutter run --dart-define=API_URL=http://10.0.2.2:4000    -> your PC from the Android emulator
///   flutter run --dart-define=API_URL=http://192.168.1.20:4000 -> your PC from a real phone on Wi-Fi
class AppConfig {
  static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: 'https://eventifyai.xvalue.et');

  /// REST API root, e.g. https://eventifyai.xvalue.et/api
  static String get apiUrl => '$baseUrl/api';

  /// Public link to an event page. Used by the share button: the web page carries
  /// link-preview tags, so Telegram/WhatsApp show the event title and banner.
  static String eventLink(int eventId) => '$baseUrl/events/$eventId';

  /// Turns a server path such as /uploads/banners/x.jpg into a full URL.
  static String? mediaUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }
}
