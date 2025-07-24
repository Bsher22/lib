class Player {
  final int? id;
  final String name;
  final DateTime createdAt;
  
  // Core player fields that match backend
  final String ageGroup;
  final String position;
  
  // Personal information
  final String? email;
  final String? phone;
  final int? jerseyNumber;
  final String? preferredPosition;
  final DateTime? birthDate;
  final int? height;  // in inches
  final int? weight;  // in lbs
  
  // UPDATED: New fields to match backend database schema
  final String skillLevel;
  final String? gender;
  
  // Relationship fields
  final int? teamId;              
  final String? teamName;         
  final int? primaryCoachId;      
  final String? primaryCoachName; 
  final int? coordinatorId;       
  final String? coordinatorName;  

  Player({
    this.id, 
    required this.name, 
    required this.createdAt,
    this.ageGroup = 'Unknown',
    this.position = 'Unknown',
    this.email,
    this.phone,
    this.jerseyNumber,
    this.preferredPosition,
    this.birthDate,
    this.height,
    this.weight,
    this.skillLevel = 'competitive',  // Default value to match backend
    this.gender,
    this.teamId,
    this.teamName,
    this.primaryCoachId,
    this.primaryCoachName,
    this.coordinatorId,
    this.coordinatorName,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      name: json['name'] ?? '',
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),
      ageGroup: json['age_group'] ?? 'Unknown',
      position: json['position'] ?? 'Unknown',
      email: json['email'],
      phone: json['phone'],
      jerseyNumber: json['jersey_number'],
      preferredPosition: json['preferred_position'],
      birthDate: json['birth_date'] != null 
        ? DateTime.parse(json['birth_date']) 
        : null,
      height: json['height'],
      weight: json['weight'],
      skillLevel: json['skill_level'] ?? 'competitive',  // UPDATED: New field
      gender: json['gender'],  // UPDATED: New field
      teamId: json['team_id'],
      teamName: json['team_name'],
      primaryCoachId: json['primary_coach_id'],
      primaryCoachName: json['primary_coach_name'],
      coordinatorId: json['coordinator_id'],
      coordinatorName: json['coordinator_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'age_group': ageGroup,
      'position': position,
      'email': email,
      'phone': phone,
      'jersey_number': jerseyNumber,
      'preferred_position': preferredPosition,
      'birth_date': birthDate?.toIso8601String(),
      'height': height,
      'weight': weight,
      'skill_level': skillLevel,  // UPDATED: New field
      'gender': gender,  // UPDATED: New field
      'team_id': teamId,
      'team_name': teamName,
      'primary_coach_id': primaryCoachId,
      'primary_coach_name': primaryCoachName,
      'coordinator_id': coordinatorId,
      'coordinator_name': coordinatorName,
    };
  }
  
  // Helper methods for UI display
  String get displayName => name;
  
  String get positionDisplay {
    switch (position.toLowerCase()) {
      case 'forward':
        return 'Forward';
      case 'defenseman':
        return 'Defenseman';
      case 'goalie':
        return 'Goalie';
      default:
        return position.split('_').map((word) => 
            word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }
  
  String get ageGroupDisplay {
    switch (ageGroup.toLowerCase()) {
      case 'youth_8_10':
        return '8-10 Years';
      case 'youth_11_14':
        return '11-14 Years';
      case 'youth_15_18':
        return '15-18 Years';
      case 'adult':
        return 'Adult';
      default:
        return ageGroup.split('_').map((word) => 
            word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }
  
  String get skillLevelDisplay {
    switch (skillLevel.toLowerCase()) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      case 'competitive':
        return 'Competitive';
      case 'elite':
        return 'Elite';
      default:
        return skillLevel.split('_').map((word) => 
            word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }
  
  String? get genderDisplay {
    if (gender == null) return null;
    switch (gender!.toLowerCase()) {
      case 'male':
      case 'm':
        return 'Male';
      case 'female':
      case 'f':
        return 'Female';
      default:
        return gender!.split('_').map((word) => 
            word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }
  
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month || 
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }
  
  String get heightDisplay {
    if (height == null) return 'Unknown';
    final feet = height! ~/ 12;
    final inches = height! % 12;
    return '${feet}\'${inches}"';
  }
  
  String get weightDisplay {
    if (weight == null) return 'Unknown';
    return '${weight} lbs';
  }
  
  // Copy with method for updates
  Player copyWith({
    int? id,
    String? name,
    DateTime? createdAt,
    String? ageGroup,
    String? position,
    String? email,
    String? phone,
    int? jerseyNumber,
    String? preferredPosition,
    DateTime? birthDate,
    int? height,
    int? weight,
    String? skillLevel,
    String? gender,
    int? teamId,
    String? teamName,
    int? primaryCoachId,
    String? primaryCoachName,
    int? coordinatorId,
    String? coordinatorName,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      ageGroup: ageGroup ?? this.ageGroup,
      position: position ?? this.position,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      preferredPosition: preferredPosition ?? this.preferredPosition,
      birthDate: birthDate ?? this.birthDate,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      skillLevel: skillLevel ?? this.skillLevel,
      gender: gender ?? this.gender,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      primaryCoachId: primaryCoachId ?? this.primaryCoachId,
      primaryCoachName: primaryCoachName ?? this.primaryCoachName,
      coordinatorId: coordinatorId ?? this.coordinatorId,
      coordinatorName: coordinatorName ?? this.coordinatorName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Player{id: $id, name: $name, position: $position, ageGroup: $ageGroup}';
  }
}