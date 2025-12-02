import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:math';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final db = FirebaseFirestore.instance;
  final TextEditingController _searchCtrl = TextEditingController();

  LocationData? _currentLocation;
  GoogleMapController? _mapController;
  List<DocumentSnapshot> _shops = [];
  double _searchRadius = 5000; // radius dalam meter
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    final loc = Location();
    _currentLocation = await loc.getLocation();
    _loadShops();
  }

  Future<void> _loadShops() async {
    QuerySnapshot query;
    if (_searchQuery.isEmpty) {
      query = await db.collection('shops').get();
    } else {
      query = await db.collection('shops')
          .where('name', isGreaterThanOrEqualTo: _searchQuery)
          .where('name', isLessThanOrEqualTo: '$_searchQuery\uf8ff')
          .get();
    }
    setState(() {
      _shops = query.docs;
    });
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    if (_currentLocation == null) return markers;

    for (var doc in _shops) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['locationLat'] == null || data['locationLng'] == null) continue;

      final distance = _distance(
        _currentLocation!.latitude!,
        _currentLocation!.longitude!,
        data['locationLat'],
        data['locationLng'],
      );
      if (distance > _searchRadius) continue;

      markers.add(
        Marker(
          markerId: MarkerId(doc.id),
          position: LatLng(data['locationLat'], data['locationLng']),
          infoWindow: InfoWindow(
            title: data['name'],
            snippet: data['category'],
          ),
        ),
      );
    }
    return markers;
  }

  double _distance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = 
        sin(dLat/2) * sin(dLat/2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) *
        sin(dLon/2) * sin(dLon/2);
    final c = 2 * atan2(sqrt(a), sqrt(1-a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Booking")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search shop',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (val) {
                _searchQuery = val.trim();
                _loadShops();
              },
            ),
          ),
          Expanded(
            child: _currentLocation == null
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
                      zoom: 14,
                    ),
                    myLocationEnabled: true,
                    markers: _buildMarkers(),
                    onMapCreated: (c) => _mapController = c,
                  ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _shops.length,
              itemBuilder: (ctx, i) {
                final data = _shops[i].data() as Map<String, dynamic>;
                Color bgColor;
                switch (data['category'] ?? 'walk-in') {
                  case 'walk-in+booking':
                    bgColor = Colors.green.shade100;
                    break;
                  case 'freelancer':
                    bgColor = Colors.blue.shade100;
                    break;
                  default:
                    bgColor = Colors.orange.shade100;
                }
                return Card(
                  color: bgColor,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(data['name'] ?? '-'),
                    subtitle: Text(data['category'] ?? '-'),
                    trailing: Text(data['phone'] ?? '-'),
                    onTap: () {
                      // Navigate to shop profile if needed
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
