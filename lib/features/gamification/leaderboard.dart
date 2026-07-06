library;

/// Timeframe for leaderboard ranking.
enum LeaderboardTimeframe {
  weekly,
  monthly,
  allTime,
}

/// Category for leaderboard ranking.
enum LeaderboardCategory {
  overall,
  workouts,
  volume,
  streaks,
  xp,
}

/// A single entry on the leaderboard.
///
/// Only users who have opted in to the leaderboard appear.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.score,
    required this.rank,
    this.avatar,
  });

  /// Unique user identifier.
  final String userId;

  /// Display name shown on the leaderboard.
  final String displayName;

  /// Numeric score (XP, volume, streak days — depends on category).
  final int score;

  /// 1-based rank position.
  final int rank;

  /// Optional avatar URL or asset path.
  final String? avatar;

  /// Formatted score with comma separators.
  String get formattedScore {
    if (score >= 1000000) {
      return '${(score / 1000000).toStringAsFixed(1)}M';
    }
    if (score >= 1000) {
      return '${(score / 1000).toStringAsFixed(1)}k';
    }
    return score.toString();
  }
}

/// A privacy-aware competitive leaderboard.
///
/// Only shows users who have explicitly opted in to leaderboard visibility.
class Leaderboard {
  const Leaderboard({
    required this.entries,
    required this.timeframe,
    required this.category,
  });

  /// All leaderboard entries, sorted by rank (ascending).
  final List<LeaderboardEntry> entries;

  /// Time window for the ranking.
  final LeaderboardTimeframe timeframe;

  /// What metric is being ranked.
  final LeaderboardCategory category;

  /// Number of participants.
  int get participantCount => entries.length;

  /// Top 3 entries (podium).
  List<LeaderboardEntry> get podium =>
      entries.where((e) => e.rank <= 3).toList();

  /// Find a specific user's entry by [userId].
  LeaderboardEntry? findUser(String userId) {
    try {
      return entries.firstWhere((e) => e.userId == userId);
    } on StateError {
      return null;
    }
  }

  /// Entries around a given rank (±[window] entries).
  List<LeaderboardEntry> entriesAroundRank(int rank, {int window = 2}) {
    return entries
        .where((e) => (e.rank - rank).abs() <= window)
        .toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));
  }
}

/// Builds a [Leaderboard] from raw user data, applying privacy filters.
///
/// Only users whose [optedInUserIds] set contains their ID are included.
class LeaderboardBuilder {
  const LeaderboardBuilder();

  /// Builds a leaderboard from a list of user scores.
  ///
  /// [userScores] is a list of (userId, displayName, score, avatar) tuples.
  /// Only users in [optedInUserIds] are included in the output.
  Leaderboard build({
    required List<(String, String, int, String?)> userScores,
    required Set<String> optedInUserIds,
    required LeaderboardTimeframe timeframe,
    required LeaderboardCategory category,
  }) {
    // Filter to opted-in users only.
    final filtered = userScores
        .where((tuple) => optedInUserIds.contains(tuple.$1))
        .toList();

    // Sort descending by score.
    filtered.sort((a, b) => b.$3.compareTo(a.$3));

    // Assign ranks (1-based, ties get same rank).
    final entries = <LeaderboardEntry>[];
    for (var i = 0; i < filtered.length; i++) {
      final tuple = filtered[i];
      // Same score as previous → same rank.
      final rank =
          (i > 0 && tuple.$3 == filtered[i - 1].$3)
              ? entries[i - 1].rank
              : i + 1;
      entries.add(LeaderboardEntry(
        userId: tuple.$1,
        displayName: tuple.$2,
        score: tuple.$3,
        rank: rank,
        avatar: tuple.$4,
      ));
    }

    return Leaderboard(
      entries: entries,
      timeframe: timeframe,
      category: category,
    );
  }
}
