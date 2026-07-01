import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uber_users_app/appInfo/app_info.dart';
import 'package:uber_users_app/models/address_models.dart';
import 'package:uber_users_app/models/prediction_model.dart';

class PredictionPlaceUI extends StatelessWidget {
  final PredictionModel? predictedPlaceData;

  /// If provided, called with the resolved drop-off when the row is tapped.
  /// When null, falls back to updating the provider and popping the screen.
  final void Function(AddressModel dropOff)? onSelected;

  const PredictionPlaceUI({
    super.key,
    this.predictedPlaceData,
    this.onSelected,
  });

  AddressModel? _buildAddress() {
    final prediction = predictedPlaceData;
    if (prediction == null ||
        prediction.latitude == null ||
        prediction.longitude == null) {
      return null;
    }

    // Photon already gives us coordinates, so no second network round-trip.
    String placeName = prediction.mainText ?? "";
    if ((prediction.secondaryText ?? "").isNotEmpty) {
      placeName = placeName.isEmpty
          ? prediction.secondaryText!
          : "$placeName, ${prediction.secondaryText}";
    }

    return AddressModel(
      latitudePosition: prediction.latitude,
      longitudePosition: prediction.longitude,
      placeName: placeName,
      humanReadableAddress: placeName,
      placeID: prediction.placeId,
    );
  }

  void _handleTap(BuildContext context) {
    final dropOff = _buildAddress();
    if (dropOff == null) return;

    if (onSelected != null) {
      onSelected!(dropOff);
    } else {
      Provider.of<AppInfoClass>(context, listen: false)
          .updateDropOffLocation(dropOff);
      Navigator.pop(context, "placeSelected");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _handleTap(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.share_location, color: Colors.grey),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      predictedPlaceData?.mainText ?? "",
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      predictedPlaceData?.secondaryText ?? "",
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
