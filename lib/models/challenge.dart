class Challenge {
  final int? challengeId;
  final String challengeTitle;
  final String? imageUrl;
  final DateTime? createdAt;

  Challenge({
    this.challengeId,
    required this.challengeTitle,
    this.imageUrl,
    this.createdAt,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      challengeId: json['challenge_id'] as int?,
      challengeTitle: json['challenge_title'] as String,
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (challengeId != null) 'challenge_id': challengeId,
      'challenge_title': challengeTitle,
      if (imageUrl != null) 'image_url': imageUrl,
      if (createdAt != null) 'created_at': createdAt?.toIso8601String(),
    };
  }
  
  // For creating new challenge (without challenge_id)
  Map<String, dynamic> toJsonForInsert() {
    return {
      'challenge_title': challengeTitle,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'image_url': imageUrl,
    };
  }
}

