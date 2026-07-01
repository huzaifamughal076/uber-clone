import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:provider/provider.dart';
import 'package:uber_users_app/appInfo/app_info.dart';
import 'package:uber_users_app/global/global_var.dart';

class PushNotificationService {
  // The service-account JSON is bundled as a (gitignored) asset instead of
  // being hardcoded here, so the private key stays out of source control.
  // Download it from: Firebase Console -> Project settings -> Service accounts
  // -> Generate new private key, and save it to:
  //   assets/fcm/service_account.json
  static Map<String, dynamic>? _serviceAccount;

  static Future<Map<String, dynamic>> _loadServiceAccount() async {
    if (_serviceAccount != null) return _serviceAccount!;
    final jsonStr =
        await rootBundle.loadString('assets/fcm/service_account.json');
    _serviceAccount = jsonDecode(jsonStr) as Map<String, dynamic>;
    return _serviceAccount!;
  }

  static Future<String> getAccessToken(
      Map<String, dynamic> serviceAccountJson) async {
    final scopes = [
      "https://www.googleapis.com/auth/firebase.messaging",
    ];

    final client = http.Client();
    try {
      final auth.AccessCredentials credentials =
          await auth.obtainAccessCredentialsViaServiceAccount(
        auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
        scopes,
        client,
      );
      return credentials.accessToken.data;
    } finally {
      client.close();
    }
  }

  static sendNotificationToSelectedDriver(
      String deviceToken, BuildContext context, String tripID) async {
    debugPrint('device token, $deviceToken');

    String dropOffDesitinationAddress =
        Provider.of<AppInfoClass>(context, listen: false)
            .dropOffLocation!
            .placeName
            .toString();
    String pickUpAddress = Provider.of<AppInfoClass>(context, listen: false)
        .pickUpLocation!
        .placeName
        .toString();
    debugPrint('pickup address is $pickUpAddress');

    late final Map<String, dynamic> serviceAccount;
    try {
      serviceAccount = await _loadServiceAccount();
    } catch (e) {
      debugPrint(
          "Missing/invalid assets/fcm/service_account.json - cannot send "
          "notification: $e");
      return;
    }

    try {
      final String projectId = serviceAccount["project_id"].toString();
      final String serverKeyTokenKey = await getAccessToken(serviceAccount);
      String endpointFirebaseCloudMessaging =
          "https://fcm.googleapis.com/v1/projects/$projectId/messages:send";

      final Map<String, dynamic> message = {
        'message': {
          'token': deviceToken,
          'notification': {
            'title': "New Trip Request From $userName",
            'body':
                "PickUp Location: $pickUpAddress \nDropOff Location: $dropOffDesitinationAddress"
          },
          'data': {
            'tripID': tripID,
          }
        }
      };

      final http.Response response = await http.post(
        Uri.parse(endpointFirebaseCloudMessaging),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $serverKeyTokenKey'
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        debugPrint("Notifcation send successfully. ${response.statusCode}");
      } else {
        debugPrint(
            'Failed to send notification, ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      debugPrint("Error sending FCM notification: $e");
    }
  }
}
