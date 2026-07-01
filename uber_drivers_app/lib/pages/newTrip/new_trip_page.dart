
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:uber_drivers_app/methods/common_method.dart';
import 'package:uber_drivers_app/models/trip_details.dart';
import 'package:uber_drivers_app/widgets/loading_dialog.dart';
import 'package:uber_drivers_app/widgets/payment_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../global/global.dart';

class NewTripPage extends StatefulWidget {
  TripDetails? newTripDetailsInfo;
  NewTripPage({super.key, this.newTripDetailsInfo});

  @override
  State<NewTripPage> createState() => _NewTripPageState();
}

class _NewTripPageState extends State<NewTripPage> {
  final MapController mapController = MapController();
  List<LatLng> coordinatesPolylineLatLngList = [];
  PolylinePoints polylinePoints = PolylinePoints();
  List<Marker> markersSet = [];
  Marker? carMarker;
  List<CircleMarker> circlesSet = [];
  List<Polyline> polyLinesSet = [];
  bool directionRequested = false;
  String statusOfTrip = "accepted";
  String durationText = "";
  String buttonTitleText = "ARRIVED";
  Color buttonColor = Colors.indigoAccent;
  String distanceText = "";
  CommonMethods commonMethods = CommonMethods();

  obtainDirectionAndDrawRoute(
      sourceLocationLatLng, destinationLocationLatLng) async {
    try {
      // Start by logging the method entry

      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) => const LoadingDialog(
          messageText: 'Please wait...',
        ),
      );

      var tripDetailsInfo = await CommonMethods.getDirectionDetailsFromAPI(
          sourceLocationLatLng, destinationLocationLatLng);

      Navigator.pop(context);

      if (tripDetailsInfo == null || tripDetailsInfo.encodedPoints == null) {
        return;
      }

      PolylinePoints pointsPolyline = PolylinePoints();
      List<PointLatLng> latLngPoints =
          pointsPolyline.decodePolyline(tripDetailsInfo.encodedPoints!);

      coordinatesPolylineLatLngList.clear();

      if (latLngPoints.isNotEmpty) {
        for (var pointLatLng in latLngPoints) {
          coordinatesPolylineLatLngList
              .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
        }
      } else {
        print("No polyline points found");
      }

      // Draw polyline + markers + circles
      setState(() {
        polyLinesSet = [
          Polyline(
            points: coordinatesPolylineLatLngList,
            color: Colors.amber,
            strokeWidth: 5,
          ),
        ];

        markersSet = [
          Marker(
            point: sourceLocationLatLng,
            width: 40,
            height: 40,
            alignment: Alignment.topCenter,
            child: const Icon(Icons.location_on, color: Colors.green, size: 40),
          ),
          Marker(
            point: destinationLocationLatLng,
            width: 40,
            height: 40,
            alignment: Alignment.topCenter,
            child:
                const Icon(Icons.location_on, color: Colors.orange, size: 40),
          ),
        ];

        circlesSet = [
          CircleMarker(
            point: sourceLocationLatLng,
            radius: 8,
            color: Colors.green,
            borderColor: Colors.orange,
            borderStrokeWidth: 3,
          ),
          CircleMarker(
            point: destinationLocationLatLng,
            radius: 8,
            color: Colors.orange,
            borderColor: Colors.green,
            borderStrokeWidth: 3,
          ),
        ];
      });

      // Fit the route on the map
      final pointsToFit = <LatLng>[
        sourceLocationLatLng,
        destinationLocationLatLng,
        ...coordinatesPolylineLatLngList,
      ];
      try {
        mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(pointsToFit),
            padding: const EdgeInsets.all(60),
          ),
        );
      } catch (_) {}
    } catch (e, stackTrace) {
      // Catch and log any errors that occur
      print("Error in obtainDirectionAndDrawRoute: $e");
      print("StackTrace: $stackTrace");
    }
  }

  getLiveLocationUpdatesOfDriver() {
    positionStreamNewTripPage =
        Geolocator.getPositionStream().listen((Position positionDriver) {
      driverCurrentPosition = positionDriver;

      LatLng driverCurrentPositionLatLng = LatLng(
          driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);

      if (mounted) {
        setState(() {
          carMarker = Marker(
            point: driverCurrentPositionLatLng,
            width: 40,
            height: 40,
            child: Image.asset("assets/images/tracking.png"),
          );
        });
      }

      try {
        mapController.move(driverCurrentPositionLatLng, 16);
      } catch (_) {}

      //update Trip Details Information
      updateTripDetailsInformation();

      //update driver location to tripRequest
      Map updatedLocationOfDriver = {
        "latitude": driverCurrentPosition!.latitude,
        "longitude": driverCurrentPosition!.longitude,
      };
      FirebaseDatabase.instance
          .ref()
          .child("tripRequest")
          .child(widget.newTripDetailsInfo!.tripID!)
          .child("driverLocation")
          .set(updatedLocationOfDriver);
    });
  }

  updateTripDetailsInformation() async {
    if (!directionRequested) {
      directionRequested = true;

      if (driverCurrentPosition == null) {
        return;
      }

      var driverLocationLatLng = LatLng(
          driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);

      LatLng dropOffDestinationLocationLatLng;
      if (statusOfTrip == "accepted") {
        dropOffDestinationLocationLatLng =
            widget.newTripDetailsInfo!.pickUpLatLng!;
      } else {
        dropOffDestinationLocationLatLng =
            widget.newTripDetailsInfo!.dropOffLatLng!;
      }

      var directionDetailsInfo = await CommonMethods.getDirectionDetailsFromAPI(
          driverLocationLatLng, dropOffDestinationLocationLatLng);

      if (directionDetailsInfo != null) {
        directionRequested = false;

        setState(() {
          durationText = directionDetailsInfo.durationTextString!;
          distanceText = directionDetailsInfo.distanceTextString!;
        });
      }
    }
  }

  endTripNow() async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => const LoadingDialog(
        messageText: 'Please wait...',
      ),
    );

    var driverCurrentLocationLatLng = LatLng(
        driverCurrentPosition!.latitude, driverCurrentPosition!.longitude);
    var directionDetailsEndTripInfo =
        await CommonMethods.getDirectionDetailsFromAPI(
            widget.newTripDetailsInfo!.pickUpLatLng!,
            driverCurrentLocationLatLng);
    Navigator.pop(context);
    // String fareamount =
    //     (commonMethods.calculateFareAmountInPKR(directionDetailsEndTripInfo!))
    //         .toString();
    String finalFareAmount = "0";
    // Placeholder for actual fare calculation
    if (bidAmount != "null") {
      finalFareAmount = bidAmount.toString();
    } else {
      finalFareAmount = fareAmount.toString();
    }

    FirebaseDatabase.instance
        .ref()
        .child("tripRequest")
        .child(widget.newTripDetailsInfo!.tripID!)
        .child("fareAmount")
        .set(finalFareAmount);

    FirebaseDatabase.instance
        .ref()
        .child("tripRequest")
        .child(widget.newTripDetailsInfo!.tripID!)
        .child("status")
        .set("ended");

    positionStreamNewTripPage!.cancel();

    displayLoadingDialog(finalFareAmount);

    saveFareAmountToDriverTotalEearning(finalFareAmount);
  }

  displayLoadingDialog(faremmount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => PaymentDialog(fareAmount: faremmount),
    );
  }

  saveFareAmountToDriverTotalEearning(String fareAmount) async {
    DatabaseReference driverEarningRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("earnings");
    await driverEarningRef.once().then((snap) {
      if (snap.snapshot.value != null) {
        double previousTotalEarning = double.parse(
          snap.snapshot.value.toString(),
        );
        double fareAmountForThisAmount = double.parse(fareAmount);
        double newTotalEarning = previousTotalEarning + fareAmountForThisAmount;
        driverEarningRef.set(newTotalEarning);
      } else {
        driverEarningRef.set(fareAmount);
      }
    });
  }

  saveDriverDataToTripInfo() async {
    Map<String, dynamic> driverDataMap = {
      "status": "accepted",
      "driverId": FirebaseAuth.instance.currentUser!.uid,
      "driverName": "$driverName $driverSecondName",
      "driverPhone": driverPhone,
      "driverPhoto": driverPhoto,
      "carDetails": "$carModel - $carNumber - $carColor",
    };

    Map<String, dynamic> driverCurrentLocation = {
      'latitude': driverCurrentPosition!.latitude.toString(),
      'longitude': driverCurrentPosition!.longitude.toString(),
    };

    await FirebaseDatabase.instance
        .ref()
        .child("tripRequest")
        .child(widget.newTripDetailsInfo!.tripID!)
        .update(driverDataMap);
    await FirebaseDatabase.instance
        .ref()
        .child("tripRequest")
        .child(widget.newTripDetailsInfo!.tripID!)
        .child("driverLocation")
        .update(driverCurrentLocation);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    saveDriverDataToTripInfo();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: FlutterMap(
                mapController: mapController,
                options: MapOptions(
                  initialCenter: driverCurrentPosition != null
                      ? LatLng(driverCurrentPosition!.latitude,
                          driverCurrentPosition!.longitude)
                      : googlePlexInitialPosition,
                  initialZoom: initialMapZoom,
                  onMapReady: () async {
                    if (driverCurrentPosition == null) return;

                    var driverCurrentLocationLatLng = LatLng(
                        driverCurrentPosition!.latitude,
                        driverCurrentPosition!.longitude);

                    var userPickUpLocationLatLng =
                        widget.newTripDetailsInfo!.pickUpLatLng;

                    await obtainDirectionAndDrawRoute(
                        driverCurrentLocationLatLng, userPickUpLocationLatLng);

                    getLiveLocationUpdatesOfDriver();
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.uber_drivers_app',
                  ),
                  PolylineLayer(polylines: polyLinesSet),
                  CircleLayer(circles: circlesSet),
                  MarkerLayer(
                    markers: [
                      ...markersSet,
                      if (carMarker != null) carMarker!,
                    ],
                  ),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(17),
                    topLeft: Radius.circular(17),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white12,
                      blurRadius: 17,
                      spreadRadius: 0.5,
                    )
                  ],
                ),
                height: 275,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          "$durationText - $distanceText",
                          style: const TextStyle(
                              color: Colors.green,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.newTripDetailsInfo!.userName ?? "No Name",
                            style: const TextStyle(
                                color: Colors.green,
                                fontSize: 20,
                                fontWeight: FontWeight.bold),
                          ),
                          GestureDetector(
                            onTap: () {
                              launchUrl(
                                Uri.parse(
                                    "tel://${widget.newTripDetailsInfo!.userPhone}"),
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(10),
                              child: Icon(Icons.phone_android_outlined,
                                  color: Colors.white),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Image.asset(
                              "assets/images/initial.png",
                              height: 16,
                              width: 16,
                            ),
                            Flexible(
                              child: Text(
                                widget.newTripDetailsInfo!.pickupAddress
                                    .toString(),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Row(
                        children: [
                          Image.asset(
                            "assets/images/final.png",
                            height: 16,
                            width: 16,
                          ),
                          Expanded(
                            child: Text(
                              widget.newTripDetailsInfo!.dropOffAddress
                                  .toString(),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (statusOfTrip == "accepted") {
                              setState(() {
                                buttonTitleText = "START TRIP";
                                buttonColor = Colors.green;
                              });
                              statusOfTrip = "arrived";
                              FirebaseDatabase.instance
                                  .ref()
                                  .child("tripRequest")
                                  .child(widget.newTripDetailsInfo!.tripID!)
                                  .child("status")
                                  .set("arrived");

                              showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (BuildContext context) =>
                                    const LoadingDialog(
                                  messageText: 'Please wait...',
                                ),
                              );

                              await obtainDirectionAndDrawRoute(
                                  widget.newTripDetailsInfo!.pickUpLatLng,
                                  widget.newTripDetailsInfo!.dropOffLatLng!);

                              Navigator.pop(context);
                            } else if (statusOfTrip == "arrived") {
                              setState(() {
                                buttonTitleText = "END TRIP";
                                buttonColor = Colors.amber;
                                statusOfTrip = "ontrip";
                                FirebaseDatabase.instance
                                    .ref()
                                    .child("tripRequest")
                                    .child(widget.newTripDetailsInfo!.tripID!)
                                    .child("status")
                                    .set("ontrip");
                              });
                            } else if (statusOfTrip == "ontrip") {
                              endTripNow();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: buttonColor),
                          child: Text(
                            buttonTitleText,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
