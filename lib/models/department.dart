class Department {
  const Department({required this.id, required this.name, this.description});

  final int id;
  final String name;
  final String? description;

  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(
      id: map['id'] as int,
      name: (map['name'] ?? '') as String,
      description: map['description'] as String?,
    );
  }
}
