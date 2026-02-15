/// Data model for a BauHouse player/resident.
class Player {
  final String id;
  final String houseStyle;
  final String accentColour;
  final String? streetId;
  final int plotNumber;
  final int currentStreak;
  final int longestStreak;
  final int builderCredits;
  final bool isPremium;
  final DateTime? lastActiveDate;
  final DateTime createdAt;

  const Player({
    required this.id,
    required this.houseStyle,
    required this.accentColour,
    this.streetId,
    required this.plotNumber,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.builderCredits = 0,
    this.isPremium = false,
    this.lastActiveDate,
    required this.createdAt,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      houseStyle: json['house_style'] as String,
      accentColour: json['accent_colour'] as String,
      streetId: json['street_id'] as String?,
      plotNumber: json['plot_number'] as int,
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      builderCredits: json['builder_credits'] as int? ?? 0,
      isPremium: json['is_premium'] as bool? ?? false,
      lastActiveDate: json['last_active_date'] != null
          ? DateTime.parse(json['last_active_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'house_style': houseStyle,
        'accent_colour': accentColour,
        'street_id': streetId,
        'plot_number': plotNumber,
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'builder_credits': builderCredits,
        'is_premium': isPremium,
        'last_active_date': lastActiveDate?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  Player copyWith({
    String? houseStyle,
    String? accentColour,
    String? streetId,
    int? plotNumber,
    int? currentStreak,
    int? longestStreak,
    int? builderCredits,
    bool? isPremium,
    DateTime? lastActiveDate,
  }) {
    return Player(
      id: id,
      houseStyle: houseStyle ?? this.houseStyle,
      accentColour: accentColour ?? this.accentColour,
      streetId: streetId ?? this.streetId,
      plotNumber: plotNumber ?? this.plotNumber,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      builderCredits: builderCredits ?? this.builderCredits,
      isPremium: isPremium ?? this.isPremium,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      createdAt: createdAt,
    );
  }
}
