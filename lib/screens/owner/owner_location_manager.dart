// lib/screens/owner/owner_location_manager.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../shared/location_picker_screen.dart';

class OwnerLocationManager {
  final User? user;
  final FirebaseFirestore db;
  final Function loadShopData;
  
  OwnerLocationManager({
    required this.user,
    required this.db,
    required this.loadShopData,
  });

  Future<void> setLocation(BuildContext context, Map<String, dynamic>? shopData) async {
    LatLng? initialLocation;
    if (shopData?['coordinates'] != null) {
      initialLocation = LatLng(
        shopData!['coordinates']['latitude'] ?? 3.1390,
        shopData['coordinates']['longitude'] ?? 101.6869,
      );
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLocation: initialLocation,
        ),
      ),
    );

    if (result != null) {
      await saveLocationToFirestore(
        context,
        result['address'],
        result['lat'],
        result['lng'],
      );
    }
  }

  Future<void> saveLocationToFirestore(BuildContext context, String address, double lat, double lng) async {
    await db.collection('shops').doc(user!.uid).set({
      'location': address,
      'coordinates': {
        'latitude': lat,
        'longitude': lng,
        'address': address,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    loadShopData();
    
    if (Navigator.of(context).mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📍 Lokasi berjaya disimpan!'), 
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget buildLocationButton(BuildContext context, Map<String, dynamic>? shopData) {
    final coordinates = shopData?['coordinates'] as Map<String, dynamic>?;
    final hasLocation = coordinates != null &&
        coordinates['latitude'] != null &&
        coordinates['latitude'] != 0.0;

    return Expanded(
      child: ElevatedButton.icon(
        onPressed: () => setLocation(context, shopData),
        icon: Icon(
          hasLocation ? Icons.location_on : Icons.location_off,
          size: 18,
          color: hasLocation ? Colors.green : Colors.orange,
        ),
        label: Text(hasLocation ? "Lokasi Set" : "Set Lokasi"),
        style: ElevatedButton.styleFrom(
          backgroundColor: hasLocation ? Colors.green[50] : Colors.orange[50],
          foregroundColor: hasLocation ? Colors.green : Colors.orange,
        ),
      ),
    );
  }
}