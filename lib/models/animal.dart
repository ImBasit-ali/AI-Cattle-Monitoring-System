/// Animal Model - Represents a cattle in the system
class Animal {
  final String id;
  final String animalId; // Unique tracking ID
  final String species; // Cow/Buffalo
  final int age; // in months
  final String healthStatus;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId; // Owner/Farm ID
  
  // Additional metadata
  final String? breed;
  final double? weight; // in kg
  final String? notes;

  Animal({
    required this.id,
    required this.animalId,
    required this.species,
    required this.age,
    required this.healthStatus,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.breed,
    this.weight,
    this.notes,
  });

  /// Create Animal from JSON
  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: json['id'] as String,
      animalId: json['animal_id'] as String,
      species: json['species'] as String,
      age: json['age'] as int,
      healthStatus: json['health_status'] as String,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userId: json['user_id'] as String,
      breed: json['breed'] as String?,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      notes: json['notes'] as String?,
    );
  }

  /// Convert Animal to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'animal_id': animalId,
      'species': species,
      'age': age,
      'health_status': healthStatus,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
      'breed': breed,
      'weight': weight,
      'notes': notes,
    };
  }

  /// Create a copy with modified fields
  Animal copyWith({
    String? id,
    String? animalId,
    String? species,
    int? age,
    String? healthStatus,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? breed,
    double? weight,
    String? notes,
  }) {
    return Animal(
      id: id ?? this.id,
      animalId: animalId ?? this.animalId,
      species: species ?? this.species,
      age: age ?? this.age,
      healthStatus: healthStatus ?? this.healthStatus,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      breed: breed ?? this.breed,
      weight: weight ?? this.weight,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() {
    return 'Animal{id: $id, animalId: $animalId, species: $species, age: $age}';
  }
}
