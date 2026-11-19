// Data models for the API responses. Each class mirrors one JSON shape from
// the backend (see backend/README.md, API reference) and is built with fromJson.
// Dates arrive as UTC ISO strings and are kept as UTC DateTime here; the
// format helpers (utils/format.dart) convert them to Addis Ababa time.

DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse('$v')?.toUtc();
double _num(dynamic v) => v == null ? 0 : (v is num ? v.toDouble() : double.tryParse('$v') ?? 0);
List<String> _strings(dynamic v) => v is List ? v.map((e) => '$e').toList() : <String>[];

/// The logged-in account (users table). role is attendee | organizer | admin.
class User {
  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final bool emailVerified;

  User({required this.id, required this.fullName, required this.email, this.phone, required this.role, this.emailVerified = true});

  factory User.fromJson(Map<String, dynamic> j) => User(
    id: j['user_id'],
    fullName: j['full_name'] ?? '',
    email: j['email'] ?? '',
    phone: j['phone_number'],
    role: j['role'] ?? 'attendee',
    emailVerified: j['email_verified'] != false,
  );

  bool get isAttendee => role == 'attendee';
  bool get isOrganizer => role == 'organizer';
  bool get isAdmin => role == 'admin';
  String get firstName => fullName.split(' ').first;
}

/// Networking profile (attendee_profiles). Also used for people in the Digital Room.
class Profile {
  final int userId;
  final String fullName;
  final String? jobTitle;
  final String? company;
  final String? bio;
  final List<String> skills;
  final List<String> interests;
  final List<String> goals;
  final String? linkedinUrl;
  final String? photo;
  final double? matchScore; // only in the Digital Room
  final String? matchExplanation; // only on a person's page
  final int? strengthScore; // only for "my" profile
  final String? strengthTip;

  Profile({
    required this.userId,
    required this.fullName,
    this.jobTitle,
    this.company,
    this.bio,
    this.skills = const [],
    this.interests = const [],
    this.goals = const [],
    this.linkedinUrl,
    this.photo,
    this.matchScore,
    this.matchExplanation,
    this.strengthScore,
    this.strengthTip,
  });

  factory Profile.fromJson(Map<String, dynamic> j) {
    final strength = j['profile_strength'];
    return Profile(
      userId: j['user_id'],
      fullName: j['full_name'] ?? '',
      jobTitle: j['job_title'],
      company: j['company'],
      bio: j['bio'],
      skills: _strings(j['skills']),
      interests: _strings(j['interests']),
      goals: _strings(j['goals']),
      linkedinUrl: j['linkedin_url'],
      photo: j['profile_photo'],
      matchScore: j['match_score'] == null ? null : _num(j['match_score']),
      matchExplanation: j['match_explanation'],
      strengthScore: strength is Map ? (strength['score'] as num?)?.toInt() : null,
      strengthTip: strength is Map ? strength['tip'] : null,
    );
  }

  /// "Flutter Developer · Freelance"
  String get headline => [jobTitle, company].where((s) => s != null && s.isNotEmpty).join(' · ');
}

class TicketType {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int total;
  final int remaining;
  final int sold;

  TicketType({required this.id, required this.name, this.description, required this.price, this.total = 0, this.remaining = 0, this.sold = 0});

  factory TicketType.fromJson(Map<String, dynamic> j) => TicketType(
    id: j['ticket_type_id'],
    name: j['type_name'] ?? '',
    description: j['description'],
    price: _num(j['price']),
    total: (j['total_quantity'] as num?)?.toInt() ?? 0,
    remaining: (j['remaining'] as num?)?.toInt() ?? 0,
    sold: (j['sold_quantity'] as num?)?.toInt() ?? 0,
  );

  bool get soldOut => remaining <= 0;
  bool get fewLeft => remaining > 0 && remaining <= 10;
}

/// An event as listed in Explore / Event detail / the organizer's list.
class EventItem {
  final int id;
  final String title;
  final String? description;
  final String? category;
  final String format; // in_person | online | hybrid
  final DateTime start;
  final DateTime end;
  final String? venueName;
  final String? venueAddress;
  final String status; // draft | published | active | completed | cancelled
  final String? banner;
  final String? organizerName;
  final bool qaEnabled;
  final double minPrice;
  final double maxPrice;
  final int capacity;
  final int checkedIn;
  final int ticketsSold;
  final List<TicketType> ticketTypes;
  final String? reason; // "Because you follow Fintech" (recommendations)
  final int myTicketCount;
  final bool myCheckedIn;
  final int similarCount;
  final List<String> similarInitials;

  EventItem({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.format = 'in_person',
    required this.start,
    required this.end,
    this.venueName,
    this.venueAddress,
    this.status = 'published',
    this.banner,
    this.organizerName,
    this.qaEnabled = false,
    this.minPrice = 0,
    this.maxPrice = 0,
    this.capacity = 0,
    this.checkedIn = 0,
    this.ticketsSold = 0,
    this.ticketTypes = const [],
    this.reason,
    this.myTicketCount = 0,
    this.myCheckedIn = false,
    this.similarCount = 0,
    this.similarInitials = const [],
  });

  factory EventItem.fromJson(Map<String, dynamic> j) {
    final similar = j['similar_people'];
    return EventItem(
      id: j['event_id'],
      title: j['title'] ?? '',
      description: j['description'],
      category: j['category'],
      format: j['format'] ?? 'in_person',
      start: _date(j['start_datetime']) ?? DateTime.now().toUtc(),
      end: _date(j['end_datetime']) ?? DateTime.now().toUtc(),
      venueName: j['venue_name'],
      venueAddress: j['venue_address'],
      status: j['status'] ?? 'published',
      banner: j['banner_image_url'],
      organizerName: j['organizer_name'],
      qaEnabled: j['qa_enabled'] == true,
      minPrice: _num(j['min_price']),
      maxPrice: _num(j['max_price']),
      capacity: (j['total_capacity'] as num?)?.toInt() ?? 0,
      checkedIn: (j['checked_in_count'] as num?)?.toInt() ?? 0,
      ticketsSold: (j['tickets_sold'] as num?)?.toInt() ?? 0,
      ticketTypes: (j['ticket_types'] as List? ?? []).map((t) => TicketType.fromJson(t)).toList(),
      reason: j['reason'],
      myTicketCount: (j['my_ticket_count'] as num?)?.toInt() ?? 0,
      myCheckedIn: j['my_checked_in'] == true,
      similarCount: similar is Map ? (similar['count'] as num?)?.toInt() ?? 0 : 0,
      similarInitials: similar is Map ? _strings(similar['initials']) : const [],
    );
  }

  bool get isLive => status == 'active';
  bool get isOnline => format == 'online';
  bool get onSale => status == 'published' || status == 'active';
  String get place => isOnline ? 'Online' : (venueName ?? 'Venue to be announced');
}

/// A ticket the attendee holds (My Tickets / Ticket QR).
class Ticket {
  final int id;
  final String code;
  final String status; // pending | confirmed | checked_in | cancelled | refunded
  final String? orderRef;
  final DateTime? checkedInAt;
  final String typeName;
  final double price;
  final EventItem event;
  final Map<String, dynamic>? pendingTransfer;
  final String? receivedFrom;
  final bool canTransfer;
  final String? holderName;
  final String? qrPayload;
  final String? qrImage; // data:image/png;base64,...

  Ticket({
    required this.id,
    required this.code,
    required this.status,
    this.orderRef,
    this.checkedInAt,
    required this.typeName,
    this.price = 0,
    required this.event,
    this.pendingTransfer,
    this.receivedFrom,
    this.canTransfer = false,
    this.holderName,
    this.qrPayload,
    this.qrImage,
  });

  factory Ticket.fromJson(Map<String, dynamic> j) {
    final type = j['ticket_type'] as Map<String, dynamic>? ?? {};
    final rf = j['received_from'];
    return Ticket(
      id: j['ticket_id'],
      code: j['ticket_code'] ?? '',
      status: j['status'] ?? 'confirmed',
      orderRef: j['order_ref'],
      checkedInAt: _date(j['checked_in_at']),
      typeName: type['type_name'] ?? '',
      price: _num(type['price']),
      event: EventItem.fromJson(Map<String, dynamic>.from(j['event'] ?? {})),
      pendingTransfer: j['pending_transfer'] is Map ? Map<String, dynamic>.from(j['pending_transfer']) : null,
      receivedFrom: rf is Map ? rf['full_name'] ?? rf['name'] : (rf is String ? rf : null),
      canTransfer: j['can_transfer'] == true,
      holderName: j['holder_name'],
      qrPayload: j['qr_payload'],
      qrImage: j['qr_image'],
    );
  }

  bool get isCheckedIn => status == 'checked_in';
  bool get isUsable => status == 'confirmed' || status == 'checked_in';
}

/// A Live Q&A question (FR-17..20).
class Question {
  final int id;
  final String text;
  final int upvotes;
  final String status; // pending | answered | hidden
  final bool pinned;
  final bool anonymous;
  final DateTime? submittedAt;
  final bool isMine;
  final bool upvotedByMe;
  final String author;

  Question({
    required this.id,
    required this.text,
    this.upvotes = 0,
    this.status = 'pending',
    this.pinned = false,
    this.anonymous = false,
    this.submittedAt,
    this.isMine = false,
    this.upvotedByMe = false,
    this.author = 'Anonymous',
  });

  factory Question.fromJson(Map<String, dynamic> j) => Question(
    id: j['question_id'],
    text: j['question_text'] ?? '',
    upvotes: (j['upvote_count'] as num?)?.toInt() ?? 0,
    status: j['status'] ?? 'pending',
    pinned: j['is_pinned'] == true,
    anonymous: j['is_anonymous'] == true,
    submittedAt: _date(j['submitted_at']),
    isMine: j['is_mine'] == true,
    upvotedByMe: j['upvoted_by_me'] == true,
    author: j['author_name'] ?? 'Anonymous',
  );
}

class AppNotification {
  final int id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;

  AppNotification({required this.id, required this.type, required this.title, required this.body, this.isRead = false, this.createdAt});

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['notification_id'],
    type: j['type'] ?? '',
    title: j['title'] ?? '',
    body: j['body'] ?? '',
    isRead: j['is_read'] == true,
    createdAt: _date(j['created_at']),
  );
}
