class PredictionModel {
  String? placeId;
  String? mainText;
  String? secondaryText;
  double? latitude;
  double? longitude;

  PredictionModel({
    this.placeId,
    this.mainText,
    this.secondaryText,
    this.latitude,
    this.longitude,
  });

  /// Builds a prediction from a Photon (OpenStreetMap) GeoJSON feature.
  /// Photon returns coordinates directly, so no separate "place details"
  /// lookup is required.
  factory PredictionModel.fromPhoton(Map<String, dynamic> feature) {
    final properties = (feature["properties"] ?? {}) as Map<String, dynamic>;
    final geometry = (feature["geometry"] ?? {}) as Map<String, dynamic>;
    final coordinates = (geometry["coordinates"] ?? []) as List;

    // GeoJSON order is [longitude, latitude].
    final double? lng =
        coordinates.isNotEmpty ? (coordinates[0] as num).toDouble() : null;
    final double? lat =
        coordinates.length > 1 ? (coordinates[1] as num).toDouble() : null;

    final String main =
        (properties["name"] ?? properties["street"] ?? properties["city"] ?? "")
            .toString();

    final secondaryParts = <String>[
      if (properties["street"] != null &&
          properties["street"].toString() != main)
        properties["street"].toString(),
      if (properties["district"] != null) properties["district"].toString(),
      if (properties["city"] != null) properties["city"].toString(),
      if (properties["state"] != null) properties["state"].toString(),
      if (properties["country"] != null) properties["country"].toString(),
    ];

    return PredictionModel(
      placeId: properties["osm_id"]?.toString(),
      mainText: main,
      secondaryText: secondaryParts.join(", "),
      latitude: lat,
      longitude: lng,
    );
  }
}
