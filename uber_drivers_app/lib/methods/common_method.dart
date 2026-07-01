import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../global/global.dart';
import '../models/direction_details.dart';

class CommonMethods {
  Future<void> checkConnectivity(BuildContext context) async {
    var connectionResults = await Connectivity().checkConnectivity();
    print("Connectivity result: $connectionResults"); // Add this line

    if (connectionResults != ConnectivityResult.wifi &&
        connectionResults != ConnectivityResult.mobile) {
      if (!context.mounted) return;
      displaySnackBar(
          "Your internet is not working. Check your connection. Try again.",
          context);
    } else {
      print("Internet is working"); // Add this line
    }
  }

  void displaySnackBar(String message, BuildContext context) {
    var snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void turnOffLocationUpdatesForHomePage() {
    if (positionStreamHomePage != null) {
      positionStreamHomePage!.pause();
    } else {
      // Handle the case where the stream is null (optional)
      print("positionStreamHomePage is null, cannot pause.");
    }
  }

  void turnOnLocationUpdatesForHomePage() {
    // Check if positionStreamHomePage is not null before resuming
    if (positionStreamHomePage != null) {
      positionStreamHomePage!.resume();
    } else {
      // Handle the case where the stream is null (optional)
      print("positionStreamHomePage is null, cannot resume.");
    }

    // Republish the driver's location to onlineDrivers (plain RTDB, no geofire)
    if (driverCurrentPosition != null) {
      FirebaseDatabase.instance
          .ref("onlineDrivers/${FirebaseAuth.instance.currentUser!.uid}")
          .set({
        "lat": driverCurrentPosition!.latitude,
        "lng": driverCurrentPosition!.longitude,
      });
    } else {
      print("driverCurrentPosition is null, cannot update location.");
    }
  }

  static sendRequestToAPI(String apiUrl) async {
    http.Response responseFromAPI = await http.get(
      Uri.parse(apiUrl),
      headers: const {"User-Agent": "uber_drivers_app/1.0 (Flutter)"},
    );

    try {
      if (responseFromAPI.statusCode == 200) {
        String dataFromApi = responseFromAPI.body;
        var dataDecoded = jsonDecode(dataFromApi);
        return dataDecoded;
      } else {
        return "error";
      }
    } catch (errorMsg) {
      return "error";
    }
  }

  ///Directions via the free OSRM demo server (lon,lat order; returns an
  ///encoded polyline plus distance in metres and duration in seconds).
  static Future<DirectionDetails?> getDirectionDetailsFromAPI(
      LatLng source, LatLng destination) async {
    String urlDirectionsAPI =
        "https://router.project-osrm.org/route/v1/driving/"
        "${source.longitude},${source.latitude};"
        "${destination.longitude},${destination.latitude}"
        "?overview=full&geometries=polyline";

    var responseFromDirectionsAPI = await sendRequestToAPI(urlDirectionsAPI);

    if (responseFromDirectionsAPI == "error") {
      return null;
    }

    if (responseFromDirectionsAPI["routes"] == null ||
        (responseFromDirectionsAPI["routes"] as List).isEmpty) {
      return null;
    }

    DirectionDetails detailsModel = DirectionDetails();
    try {
      var route = responseFromDirectionsAPI["routes"][0];

      double distanceMeters = (route["distance"] as num).toDouble();
      double durationSeconds = (route["duration"] as num).toDouble();

      detailsModel.distanceValueDigits = distanceMeters.round();
      detailsModel.durationValueDigits = durationSeconds.round();
      detailsModel.encodedPoints = route["geometry"];

      detailsModel.distanceTextString =
          "${(distanceMeters / 1000).toStringAsFixed(1)} km";

      int totalMinutes = (durationSeconds / 60).round();
      int hours = totalMinutes ~/ 60;
      int minutes = totalMinutes % 60;
      detailsModel.durationTextString =
          hours > 0 ? "$hours hours $minutes mins" : "$minutes mins";
    } catch (e) {
      return null;
    }

    return detailsModel;
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
        (directionDetails.distanceValueDigits! / 1000) * distancePerKmAmountPKR;
    double totalDurationSpendFareAmountPKR =
        (directionDetails.durationValueDigits! / 60) *
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
}
