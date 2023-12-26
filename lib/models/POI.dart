class POI{
  String id;
  String name;
  double? latitude;
  double? longitude;
  String? description;
  String? photoUrl;
  int? likes;
  int? dislikes;
  String? createdBy;
  double? grade;
  String? category;
  String? locationId;

  POI(
      this.id,
      this.name,
      this.latitude,
      this.longitude,
      this.description,
      this.photoUrl,
      this.likes,
      this.dislikes,
      this.createdBy,
      this.grade,
      this.category,
      this.locationId
      );
  factory POI.fromJson(Map<String, dynamic> json) {
    POI aux= POI(
      json['id'] ?? '',
      json['name'] ?? '',
      json['latitude'],
      json['longitude'],
      json['description'],
      json['photoUrl'],
      json['likes'],
      json['dislikes'],
      json['createdBy'],
      json['grade'],
      json['category'],
      json['locationId'],
    );
    return aux;
  }

  // Método para converter a instância de POI em um mapa JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
      'photoUrl': photoUrl,
      'likes': likes,
      'dislikes': dislikes,
      'createdBy': createdBy,
      'grade': grade,
      'category': category,
      'locationId': locationId,
    };
  }
}