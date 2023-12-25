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
}