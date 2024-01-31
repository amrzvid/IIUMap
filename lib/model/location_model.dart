class LocationModel {

  String name;
  String latitude;
  String longitude;

  LocationModel({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory LocationModel.fromMap(Map<String, dynamic> map) {
    return LocationModel(
      name: map['name'] ?? '',
      latitude: map['latitude'] ?? '',
      longitude: map['longitude'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name' : name,
      'latitude' : latitude,
      'longitude' : longitude,
    };
  }
}




