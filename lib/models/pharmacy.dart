class Pharmacy {
  final String name;
  final String district;
  final String address;
  final String phone;
  final double lat;
  final double lng;
  double? distanceMeters;

  Pharmacy({
    required this.name,
    required this.district,
    required this.address,
    required this.phone,
    required this.lat,
    required this.lng,
    this.distanceMeters,
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    final loc = (json['loc'] ?? '').toString();
    double lat = 0.0;
    double lng = 0.0;

    if (loc.contains(',')) {
      final parts = loc.split(',');
      if (parts.isNotEmpty) {
        lat = double.tryParse(parts[0].trim()) ?? 0.0;
      }
      if (parts.length > 1) {
        lng = double.tryParse(parts[1].trim()) ?? 0.0;
      }
    }

    return Pharmacy(
      name: (json['name'] ?? '').toString(),
      district: (json['dist'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      lat: lat,
      lng: lng,
    );
  }
}
