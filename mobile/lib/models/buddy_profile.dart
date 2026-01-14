class BuddyProfile {
  final String id;
  final String displayName;
  final int? age;
  final String gender;
  final List<String> languages;
  final String from;
  final String to;

  BuddyProfile({
    required this.id,
    required this.displayName,
    required this.age,
    required this.gender,
    required this.languages,
    required this.from,
    required this.to,
  });

  factory BuddyProfile.fromJson(Map<String, dynamic> json) {
    return BuddyProfile(
      id: json['id'],
      displayName: json['displayName'],
      age: (json['age'] is num) ? (json['age'] as num).toInt() : null,
      gender: json['gender'],
      languages: List<String>.from(json['languages']),
      from: json['from'],
      to: json['to'],
    );
  }
}
