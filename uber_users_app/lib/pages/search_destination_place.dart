import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:uber_users_app/appInfo/app_info.dart';
import 'package:uber_users_app/main.dart';
import 'package:uber_users_app/methods/common_methods.dart';
import 'package:uber_users_app/models/address_models.dart';
import 'package:uber_users_app/models/prediction_model.dart';
import 'package:uber_users_app/widgets/prediction_place_ui.dart';

class SearchDestinationPlace extends StatefulWidget {
  const SearchDestinationPlace({super.key});

  @override
  State<SearchDestinationPlace> createState() => _SearchDestinationPlaceState();
}

class _SearchDestinationPlaceState extends State<SearchDestinationPlace> {
  TextEditingController pickUpTextEditingController = TextEditingController();
  TextEditingController destinationTextEditingController =
      TextEditingController();

  final MapController _previewMapController = MapController();
  AddressModel? selectedDropOff;
  List<LatLng> previewRoutePoints = [];

  List<PredictionModel> dropOffPredictionsPlacesList = [];
  searchLocation(String locationName) async {
    if (locationName.length > 1) {
      // Autocomplete via the free Photon (OpenStreetMap) geocoder. Bias the
      // results toward the user's current pickup location when we have it.
      final pickUp =
          Provider.of<AppInfoClass>(context, listen: false).pickUpLocation;
      String bias = "";
      if (pickUp?.latitudePosition != null &&
          pickUp?.longitudePosition != null) {
        bias = "&lat=${pickUp!.latitudePosition}&lon=${pickUp.longitudePosition}";
      }

      String apiPlacesUrl =
          "https://photon.komoot.io/api/?q=${Uri.encodeComponent(locationName)}"
          "&limit=8&lang=en$bias";
      debugPrint('API PLACE URL $apiPlacesUrl');

      var responseFromPlacesAPI =
          await CommonMethods.sendRequestToAPI(apiPlacesUrl);

      if (responseFromPlacesAPI == "error") {
        if (mounted) {
          CommonMethods().displaySnackBar(
            "Place search failed. Check your internet connection.",
            context,
          );
        }
        return;
      }

      var featuresList = (responseFromPlacesAPI["features"] ?? []) as List;
      var predictionsList = featuresList
          .map((feature) =>
              PredictionModel.fromPhoton(feature as Map<String, dynamic>))
          .where((prediction) =>
              prediction.latitude != null &&
              prediction.longitude != null &&
              (prediction.mainText ?? "").isNotEmpty)
          .toList();

      if (mounted) {
        setState(() {
          dropOffPredictionsPlacesList = predictionsList;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String userAddress = Provider.of<AppInfoClass>(context, listen: false)
            .pickUpLocation
            ?.humanReadableAddress ??
        '';

    debugPrint('User Pick Up Location $userAddress');

    pickUpTextEditingController.text = userAddress;
    mq = MediaQuery.sizeOf(context);
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                elevation: 5,
                
                child: Container(
                  //height: mq.height * 0.25,
                  decoration: const BoxDecoration(
                    //color: Colors.black12,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5.0,
                        spreadRadius: 0.5,
                        offset: Offset(0.7, 0.7),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 24, top: 20, right: 24, bottom: 30),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 6,
                        ),
                        Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.black,
                              ),
                            ),
                            const Center(
                              child: Text(
                                "Set Dropoff Location",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 18,
                        ),
                        Row(
                          children: [
                            Image.asset(
                              "assets/images/initial.png",
                              height: 16,
                              width: 16,
                            ),
                            const SizedBox(
                              width: 18,
                            ),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white60,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: TextField(
                                    controller: pickUpTextEditingController,
                                    decoration: const InputDecoration(
                                      hintText: "Pickup Address",
                                      fillColor: Colors.white60,
                                      filled: true,
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.only(
                                          left: 11, top: 9, bottom: 9),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 11,
                        ),
                        Row(
                          children: [
                            Image.asset(
                              "assets/images/final.png",
                              height: 16,
                              width: 16,
                            ),
                            const SizedBox(
                              width: 18,
                            ),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white60,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: TextField(
                                    controller: destinationTextEditingController,
                                    onChanged: (value) {
                                      if (selectedDropOff != null) {
                                        setState(() {
                                          selectedDropOff = null;
                                          previewRoutePoints = [];
                                        });
                                      }
                                      searchLocation(value);
                                    },
                                    decoration: const InputDecoration(
                                      hintText: "Destination Address",
                                      fillColor: Colors.white60,
                                      filled: true,
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.only(
                                          left: 11, top: 9, bottom: 9),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              //display the prediction results
              if (selectedDropOff == null &&
                  dropOffPredictionsPlacesList.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 5,
                    horizontal: 5,
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(0),
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 5,
                        child: PredictionPlaceUI(
                          predictedPlaceData:
                              dropOffPredictionsPlacesList[index],
                          onSelected: (dropOff) {
                            Provider.of<AppInfoClass>(context, listen: false)
                                .updateDropOffLocation(dropOff);
                            FocusScope.of(context).unfocus();
                            setState(() {
                              selectedDropOff = dropOff;
                              dropOffPredictionsPlacesList = [];
                              previewRoutePoints = [];
                              destinationTextEditingController.text =
                                  dropOff.placeName ?? "";
                            });
                            _loadPreviewRoute();
                          },
                        ),
                      );
                    },
                    separatorBuilder: (BuildContext context, int index) =>
                        const SizedBox(
                      height: 10,
                    ),
                    itemCount: dropOffPredictionsPlacesList.length,
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                  ),
                ),

              //map preview once a destination is chosen
              if (selectedDropOff != null) _buildMapPreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapPreview() {
    final pickUp =
        Provider.of<AppInfoClass>(context, listen: false).pickUpLocation;

    final dropLatLng = LatLng(
      selectedDropOff!.latitudePosition!,
      selectedDropOff!.longitudePosition!,
    );

    final bool hasPickup = pickUp?.latitudePosition != null &&
        pickUp?.longitudePosition != null;
    final LatLng? pickLatLng = hasPickup
        ? LatLng(pickUp!.latitudePosition!, pickUp.longitudePosition!)
        : null;

    final points = <LatLng>[if (pickLatLng != null) pickLatLng, dropLatLng];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: mq.height * 0.42,
              child: FlutterMap(
                mapController: _previewMapController,
                options: MapOptions(
                  initialCenter: dropLatLng,
                  initialZoom: 13,
                  onMapReady: () => _fitPreviewCamera(points),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.uber_users_app',
                  ),
                  if (pickLatLng != null)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: previewRoutePoints.isNotEmpty
                              ? previewRoutePoints
                              : [pickLatLng, dropLatLng],
                          color: Colors.pink,
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      if (pickLatLng != null)
                        Marker(
                          point: pickLatLng,
                          width: 44,
                          height: 44,
                          child: const Icon(
                            Icons.person_pin_circle,
                            color: Colors.blue,
                            size: 44,
                          ),
                        ),
                      Marker(
                        point: dropLatLng,
                        width: 40,
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.redAccent,
                          size: 40,
                        ),
                      ),
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
          ),
          const SizedBox(height: 8),
          Text(
            selectedDropOff!.placeName ?? "",
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context, "placeSelected"),
              child: const Text(
                "Confirm Destination",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fetches the road-following route (OSRM) between pickup and the selected
  /// drop-off and draws it on the preview map.
  Future<void> _loadPreviewRoute() async {
    final pickUp =
        Provider.of<AppInfoClass>(context, listen: false).pickUpLocation;
    if (pickUp?.latitudePosition == null ||
        pickUp?.longitudePosition == null ||
        selectedDropOff?.latitudePosition == null ||
        selectedDropOff?.longitudePosition == null) {
      return;
    }

    final pickLatLng =
        LatLng(pickUp!.latitudePosition!, pickUp.longitudePosition!);
    final dropLatLng = LatLng(
        selectedDropOff!.latitudePosition!, selectedDropOff!.longitudePosition!);

    final details =
        await CommonMethods.getDirectionDetailsFromAPI(pickLatLng, dropLatLng);

    if (!mounted || details?.encodedPoints == null) return;

    final decoded =
        PolylinePoints().decodePolyline(details!.encodedPoints!);
    final points =
        decoded.map((p) => LatLng(p.latitude, p.longitude)).toList();

    if (points.isEmpty) return;

    setState(() {
      previewRoutePoints = points;
    });

    _fitPreviewCamera([pickLatLng, dropLatLng, ...points]);
  }

  void _fitPreviewCamera(List<LatLng> points) {
    if (points.length < 2) return;
    try {
      _previewMapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(50),
        ),
      );
    } catch (_) {
      // Map not rendered yet; onMapReady will handle the initial fit.
    }
  }
}
