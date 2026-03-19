// lib/data/models/player_profile.dart
// Phase 2 — Foundation
// Spec: supabase-agent-spec.md § Table: player_profiles

class PlayerProfile {
  final String id;           // player_profiles.id — used as user_id FK in child tables
  final String authId;       // player_profiles.auth_id — matches auth.uid()
  final String? displayName;
  final bool isGuest;
  final int currentStreak;
  final int longestStreak;
  final int totalWordsFound;
  final DateTime createdAt;

  const PlayerProfile({
    required this.id,
    required this.authId,
    this.displayName,
    required this.isGuest,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalWordsFound,
    required this.createdAt,
  });

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
        id: json['id'] as String,
        authId: json['auth_id'] as String,
        displayName: json['display_name'] as String?,
        isGuest: (json['is_guest'] as bool?) ?? true,
        currentStreak: (json['current_streak'] as int?) ?? 0,
        longestStreak: (json['longest_streak'] as int?) ?? 0,
        totalWordsFound: (json['total_words_found'] as int?) ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  String get welcomeName => displayName ?? 'Guest';
}
