import 'package:firebase_auth/firebase_auth.dart';
import 'package:latlong2/latlong.dart';

String userName = "";
String userPhone = "";
String userEmail = "";
String userID = FirebaseAuth.instance.currentUser!.uid;
const LatLng googlePlexInitialPosition =
    LatLng(37.42796133580664, -122.085749655962);
const double initialMapZoom = 14.4746;
