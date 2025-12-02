// LIB/SCREENS/LOCATION_PICKER_SCREEN.DART
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// HAPUS import google_places_flutter yang ada
import 'package:geocoding/geocoding.dart' as geo;
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  
  const LocationPickerScreen({super.key, this.initialLocation});
  
  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late GoogleMapController mapController;
  
  LatLng _selectedLocation = const LatLng(3.1390, 101.6869);
  Marker? _marker;
  String _address = "Pilih lokasi pada peta...";
  bool _loadingAddress = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
    }
    _addMarker(_selectedLocation);
    _getAddressFromLatLng(_selectedLocation);
  }

  void _addMarker(LatLng position) {
    setState(() {
      _marker = Marker(
        markerId: const MarkerId('selected-location'),
        position: position,
        draggable: true,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Lokasi Kedai Anda'),
        onDragEnd: (newPosition) {
          _selectedLocation = newPosition;
          _getAddressFromLatLng(newPosition);
        },
      );
    });
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    setState(() => _loadingAddress = true);
    
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${latLng.latitude}&lon=${latLng.longitude}&addressdetails=1'),
        headers: {'User-Agent': 'BarberApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _address = data['display_name'] ?? "Alamat tidak ditemui";
        });
      }
    } catch (e) {
      // Fallback ke geocoding package
      try {
        final placemarks = await geo.placemarkFromCoordinates(latLng.latitude, latLng.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          setState(() {
            _address = "${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}";
          });
        }
      } catch (e) {
        setState(() {
          _address = "Koordinat: ${latLng.latitude.toStringAsFixed(6)}, ${latLng.longitude.toStringAsFixed(6)}";
        });
      }
    } finally {
      setState(() => _loadingAddress = false);
    }
  }

  // ✅ FIXED: SEARCH FUNCTION TANPA GOOGLE_PLACES_FLUTTER
  Future<void> _openSearch() async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cari Lokasi"),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Contoh: Kuala Lumpur, KLCC, Ampang',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, _searchController.text),
            child: const Text('Cari'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _searchWithOpenStreetMap(result);
    }
  }

  Future<void> _searchWithOpenStreetMap(String query) async {
    try {
      final response = await http.get(
        Uri.parse('https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&countrycodes=my&limit=1'),
        headers: {'User-Agent': 'BarberApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          final newLocation = LatLng(lat, lon);
          
          setState(() => _selectedLocation = newLocation);
          _addMarker(newLocation);
          _getAddressFromLatLng(newLocation);
          
          mapController.animateCamera(CameraUpdate.newLatLngZoom(newLocation, 16));
        } else {
          _showError('Lokasi tidak ditemui');
        }
      }
    } catch (e) {
      _showError('Gagal mencari lokasi');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
    ));
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi Kedai'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _openSearch,
            tooltip: 'Cari Tempat',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _selectedLocation, 
              zoom: 14
            ),
            markers: _marker != null ? {_marker!} : {},
            onTap: (LatLng location) {
              setState(() => _selectedLocation = location);
              _addMarker(location);
              _getAddressFromLatLng(location);
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          
          // Address & Confirm Button
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alamat Terpilih:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _loadingAddress ? 'Mengambil alamat...' : _address,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, {
                              'address': _address,
                              'lat': _selectedLocation.latitude,
                              'lng': _selectedLocation.longitude,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Simpan Lokasi'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}