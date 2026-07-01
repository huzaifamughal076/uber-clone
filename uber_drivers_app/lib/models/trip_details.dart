import 'package:latlong2/latlong.dart';

class TripDetails
{
  String? tripID;

  LatLng? pickUpLatLng;
  String? pickupAddress;

  LatLng? dropOffLatLng;
  String? dropOffAddress;

  String? userName;
  String? userPhone;


  TripDetails({
    this.tripID,
    this.pickUpLatLng,
    this.pickupAddress,
    this.dropOffLatLng,
    this.dropOffAddress,
    this.userName,
    this.userPhone,
  });
}