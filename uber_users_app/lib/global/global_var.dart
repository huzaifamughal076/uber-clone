import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

String userName = "";
String userPhone = "";
String userEmail = "";
String userID = FirebaseAuth.instance.currentUser!.uid;
const String googleMapKey = "AIzaSyAMx-fK5PvxTMJBCH1dkwWWZJ_0bvhMyGc";
const String stripeSecretAPIKey = "sk_test_51DemoSecretKeyabcdefghijklmnopqrstuvwxyz";
const String stripePublishedKey = "pk_test_51DemoPublishedKeyabcdefghijklmnopqrstuvwxyz";
const CameraPosition googlePlexInitialPosition = CameraPosition(
  target: LatLng(37.42796133580664, -122.085749655962),
  zoom: 14.4746,
);
