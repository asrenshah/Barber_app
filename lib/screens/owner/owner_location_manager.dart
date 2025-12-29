import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../shared/location_picker_screen.dart';

class OwnerLocationManager {
  final User? user;
  final FirebaseFirestore db;
  final Function loadShopData;
  Location? _locationService;
  
  OwnerLocationManager({
    required this.user,
    required this.db,
    required this.loadShopData,
  }) {
    _locationService = Location();
  }

  Future<void> setLocation(BuildContext context, Map<String, dynamic>? shopData) async {
    // CHECK PERMISSION DULU
    try {
      final serviceEnabled = await _locationService!.serviceEnabled();
      if (!serviceEnabled) {
        final enabled = await _locationService!.requestService();
        if (!enabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perlu menghidupkan servis lokasi')),
          );
          return;
        }
      }

      final permission = await _locationService!.hasPermission();
      if (permission == PermissionStatus.denied) {
        final newPermission = await _locationService!.requestPermission();
        if (newPermission != PermissionStatus.granted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perlu memberikan kebenaran lokasi')),
          );
          return;
        }
      }
    } catch (e) {
      print('Location permission error: $e');
    }

    LatLng? initialLocation;
    if (shopData?['coordinates'] != null) {
      initialLocation = LatLng(
        shopData!['coordinates']['latitude'] ?? 3.1390,
        shopData['coordinates']['longitude'] ?? 101.6869,
      );
    } else {
      // DAPATKAN CURRENT LOCATION
      try {
        final currentLocation = await _locationService!.getLocation();
        initialLocation = LatLng(
          currentLocation.latitude ?? 3.1390,
          currentLocation.longitude ?? 101.6869,
        );
      } catch (e) {
        initialLocation = const LatLng(3.1390, 101.6869); // DEFAULT KL
      }
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
    // SHOW LOADING
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      await db.collection('shops').doc(user!.uid).set({
        'location': address,
        'coordinates': {
          'latitude': lat,
          'longitude': lng,
          'address': address,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      Navigator.pop(context); // Remove loading
      loadShopData();
      
      if (Navigator.of(context).mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📍 Lokasi berjaya disimpan!'), 
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      Navigator.pop(context); // Remove loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Ralat menyimpan lokasi: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error saving location: $e');
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
        label: Text(hasLocation ? "Ubah Lokasi" : "Set Lokasi"),
        style: ElevatedButton.styleFrom(
          backgroundColor: hasLocation ? Colors.green[50] : Colors.orange[50],
          foregroundColor: hasLocation ? Colors.green : Colors.orange,
        ),
      ),
    );
  }
}