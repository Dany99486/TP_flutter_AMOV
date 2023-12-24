class POI{
  String id;
  String name;
  double? latitude;
  double? longitude;
  String? description;
  String? photoUrl;
  List<String>? reportedBy;
  int? likes;
  int? dislikes;
  String? createdBy;
  int? report;
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
      this.reportedBy,
      this.likes,
      this.dislikes,
      this.createdBy,
      this.report,
      this.grade,
      this.category,
      this.locationId
      );
}