class Building {
  final int id;
  final String buildingName;
  final String location;
  final String? completionDate;
  final String? createdAt;

  Building({
    required this.id,
    required this.buildingName,
    required this.location,
    this.completionDate,
    this.createdAt,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: json['building_id'],
      buildingName: json['building_name'] ?? '',
      location: json['location'] ?? '',
      completionDate: json['completion_date'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'building_id': id,
      'building_name': buildingName,
      'location': location,
      'completion_date': completionDate,
    };
  }
}
