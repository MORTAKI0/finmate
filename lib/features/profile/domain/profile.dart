class Profile {
  final String id;
  final String? displayName;
  final String baseCurrency; // ISO-4217, e.g., USD
  final String theme; // light | dark | system

  const Profile({
    required this.id,
    required this.displayName,
    required this.baseCurrency,
    required this.theme,
  });

  Profile copyWith({
    String? id,
    String? displayName,
    String? baseCurrency,
    String? theme,
  }) {
    return Profile(
      id: id ?? this.id,
      displayName: displayName,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      theme: theme ?? this.theme,
    );
  }

  static Profile fromMap(Map<String, dynamic> m) => Profile(
        id: m['id'] as String,
        displayName: m['display_name'] as String?,
        baseCurrency: (m['base_currency'] as String?) ?? 'USD',
        theme: (m['theme'] as String?) ?? 'system',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'display_name': displayName,
        'base_currency': baseCurrency,
        'theme': theme,
      };
}

