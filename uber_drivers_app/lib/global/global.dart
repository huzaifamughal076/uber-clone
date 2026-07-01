import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

String userName = '';
String userEmail = '';
const LatLng googlePlexInitialPosition =
    LatLng(37.42796133580664, -122.085749655962);
const double initialMapZoom = 14.4746;

StreamSubscription<Position>? positionStreamHomePage;
StreamSubscription<Position>? positionStreamNewTripPage;


int driverTripRequestTimeout = 40;

final audioPlayer = AudioPlayer();

Position? driverCurrentPosition;

String driverName = "";
String driverPhone = "";
String driverPhoto = "";
String driverEmail = "";
String carModel = "";
String carColor = "";
String carNumber = "";
String driverSecondName = "";
String address = "";
String ratting = "";
String bidAmount = "";
String fareAmount = "";
