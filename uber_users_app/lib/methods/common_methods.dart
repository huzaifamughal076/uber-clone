import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:uber_users_app/appInfo/app_info.dart';
import 'package:uber_users_app/models/address_models.dart';

import '../models/direction_details.dart';

class CommonMethods {
  checkConnectivity(BuildContext context) async {
    var connectionResult = await Connectivity().checkConnectivity();

    if (connectionResult != ConnectivityResult.mobile &&
        connectionResult != ConnectivityResult.wifi) {
      if (!context.mounted) return;
      displaySnackBar(
          "Your Internet is not Available. Check your connection. Try Again.",
          context);
    }
  }

  displaySnackBar(String messageText, BuildContext context) {
    var snackBar = SnackBar(content: Text(messageText));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static sendRequestToAPI(String apiUrl) async {
    // A descriptive User-Agent is required by OpenStreetMap services
    // (Nominatim will reject requests without one).
    http.Response responseFromAPI = await http.get(
      Uri.parse(apiUrl),
      headers: const {"User-Agent": "uber_users_app/1.0 (Flutter)"},
    );

    try {
      if (responseFromAPI.statusCode == 200) {
        String dataFromApi = responseFromAPI.body;
        var dataDecoded = jsonDecode(dataFromApi);
        return dataDecoded;
      } else {
        debugPrint('error');
        return "error";
      }
    } catch (errorMsg) {
      debugPrint(errorMsg.toString());
      return "error";
    }
  }

  ///Reverse GeoCoding
  static Future<String> convertGeoGraphicCoOrdinatesIntoHumanReadableAddress(
      Position position, BuildContext context) async {
    String humanReadableAddress = "";
    // Reverse geocoding via OpenStreetMap Nominatim (free, no API key).
    String apiGeoCodingUrl =
        "https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1";

    var responseFromAPI = await sendRequestToAPI(apiGeoCodingUrl);

    if (responseFromAPI != "error" && responseFromAPI["display_name"] != null) {
      humanReadableAddress = responseFromAPI["display_name"];

      AddressModel model = AddressModel();
      model.humanReadableAddress = humanReadableAddress;
      model.placeName = humanReadableAddress;
      model.longitudePosition = position.longitude;
      model.latitudePosition = position.latitude;

      if (context.mounted) {
        Provider.of<AppInfoClass>(context, listen: false)
            .updatePickUpLocation(model);
      }
    }

    return humanReadableAddress;
  }

  /// This method shortens the full address by extracting key parts.
  static String shortenAddress(String fullAddress) {
    // Split the address by commas
    List<String> parts = fullAddress.split(',');

    // Return a shorter version of the address: e.g., "Street Name, City"
    if (parts.length >= 2) {
      return "${parts[0].trim()}, ${parts[1].trim()}";
    }

    // If the address has fewer parts, return it as is
    return fullAddress;
  }

  static Future<DirectionDetails?> getDirectionDetailsFromAPI(
      LatLng source, LatLng destination) async {
    // Routing via the free OSRM demo server. Note OSRM expects lon,lat order
    // and returns an encoded polyline (precision 5) plus distance (m) and
    // duration (s).
    String urlDirectionAPI =
        "https://router.project-osrm.org/route/v1/driving/"
        "${source.longitude},${source.latitude};"
        "${destination.longitude},${destination.latitude}"
        "?overview=full&geometries=polyline";

    debugPrint("URL: $urlDirectionAPI");

    var responseFromDirectionAPI = await sendRequestToAPI(urlDirectionAPI);

    if (responseFromDirectionAPI == "error") {
      debugPrint("Error in response");
      return null;
    }

    if (responseFromDirectionAPI["routes"] == null ||
        (responseFromDirectionAPI["routes"] as List).isEmpty) {
      debugPrint("No routes found in the response.");
      return null;
    }

    DirectionDetails directionDetails = DirectionDetails();
    try {
      var route = responseFromDirectionAPI["routes"][0];

      double distanceMeters = (route["distance"] as num).toDouble();
      double durationSeconds = (route["duration"] as num).toDouble();

      directionDetails.distanceValueDigit = distanceMeters.round();
      directionDetails.durationValueDigit = durationSeconds.round();
      directionDetails.encodedPoints = route["geometry"];

      directionDetails.distanceTextString =
          "${(distanceMeters / 1000).toStringAsFixed(1)} km";

      int totalMinutes = (durationSeconds / 60).round();
      int hours = totalMinutes ~/ 60;
      int minutes = totalMinutes % 60;
      directionDetails.durationTextString =
          hours > 0 ? "$hours hours $minutes mins" : "$minutes mins";
    } catch (e) {
      debugPrint("Error processing response data: $e");
      return null;
    }
    return directionDetails;
  }

  calculateFareAmountInPKR(DirectionDetails directionDetails,
      {double surgeMultiplier = 1.0}) {
    double distancePerKmAmountPKR = 20; // 20 PKR per km
    double durationPerMinuteAmountPKR = 15; // 15 PKR per minute
    double baseFareAmountPKR = 150; // Base fare in PKR
    double bookingFeePKR = 50; // Booking fee in PKR
    double minimumFarePKR = 200; // Minimum fare in PKR

    // Calculate fare based on distance and time
    double totalDistanceTravelledFareAmountPKR =
        (directionDetails.distanceValueDigit! / 1000) * distancePerKmAmountPKR;
    double totalDurationSpendFareAmountPKR =
        (directionDetails.durationValueDigit! / 60) *
            durationPerMinuteAmountPKR;

    // Total fare before applying surge
    double totalFareBeforeSurgePKR = baseFareAmountPKR +
        totalDistanceTravelledFareAmountPKR +
        totalDurationSpendFareAmountPKR +
        bookingFeePKR;

    // Apply surge pricing
    double overAllTotalFareAmountPKR =
        totalFareBeforeSurgePKR * surgeMultiplier;

    // Apply minimum fare
    if (overAllTotalFareAmountPKR < minimumFarePKR) {
      overAllTotalFareAmountPKR = minimumFarePKR;
    }

    return overAllTotalFareAmountPKR.toStringAsFixed(2);
  }

  // Utility function to format time from total minutes into "X hours Y mins"
  String formatTime(int totalMinutes) {
    int hours = totalMinutes ~/ 60; // Get the number of full hours
    int minutes = totalMinutes % 60; // Get the remaining minutes
    if (hours > 0) {
      return "$hours hours $minutes mins";
    } else {
      return "$minutes mins"; // If there are no hours, just show minutes
    }
  }
}
