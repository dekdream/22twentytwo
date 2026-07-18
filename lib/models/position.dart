class PositionModel {
  const PositionModel({
    required this.id,
    this.departmentId,
    required this.name,
    required this.salary,
  });

  final int id;
  final int? departmentId;
  final String name;
  final double salary;

  factory PositionModel.fromMap(Map<String, dynamic> map) {
    return PositionModel(
      id: map['id'] as int,
      departmentId: map['department_id'] as int?,
      name: (map['name'] ?? '') as String,
      salary: ((map['salary'] ?? 0) as num).toDouble(),
    );
  }
}
