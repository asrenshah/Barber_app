import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'dart:math';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  // ============================================
  //  CONFIGURATION
  // ============================================
  final TextEditingController _searchCtrl = TextEditingController();
  double _searchRadius = 5000; // 5km in meters
  String _searchQuery = '';
  
  // MAP & CARDS SYNC
  final PageController _pageController = PageController(viewportFraction: 0.85);
  GoogleMapController? _mapController;
  LocationData? _currentLocation;
  
  // DATA - GANTI TYPE KE SIMPLE LIST
  List<Map<String, dynamic>> _allShops = [];
  List<Map<String, dynamic>> _filteredShops = [];
  int _activeShopIndex = 0;
  
  // UI THEME - FIX: GANTI const DENGAN final
  final Color _primaryColor = const Color(0xFFD4AF37); // Gold
  final Color _backgroundColor = const Color(0xFF2C1810); // Dark brown
  final String _defaultShopImage = 'https://images.unsplash.com/photo-1599351431202-1e0f0137899a?w=400&h=250&fit=crop';

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    // Load mock data untuk UI testing
    _loadMockShops();
  }

  // ============================================
  //  1. GET USER LOCATION
  // ============================================
  Future<void> _getUserLocation() async {
    try {
      final loc = Location();
      bool serviceEnabled = await loc.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await loc.requestService();
        if (!serviceEnabled) return;
      }
      
      PermissionStatus permission = await loc.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await loc.requestPermission();
        if (permission != PermissionStatus.granted) return;
      }
      
      _currentLocation = await loc.getLocation();
      print('📍 User location: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
      setState(() {});
      
    } catch (e) {
      print('⚠️ Location error: $e');
      // Fallback to KL coordinates
      _currentLocation = LocationData.fromMap({
        'latitude': 3.106024,
        'longitude': 101.752589,
      });
      setState(() {});
    }
  }

  // ============================================
  //  2. LOAD MOCK SHOPS (UI TESTING) - FIXED!
  // ============================================
  Future<void> _loadMockShops() async {
    final List<Map<String, dynamic>> mockShops = [
      {
        'id': 'mock_shop_1',
        'name': 'The Last Barbershop',
        'category': 'walk-in+booking',
        'phone': '0192619454',
        'bannerImage': 'https://images.unsplash.com/photo-1599351431202-1e0f0137899a?w=400&h=250&fit=crop',
        'profileImage': 'https://images.unsplash.com/photo-1567894340315-735d7c361db0?w=200&h=200&fit=crop',
        'coordinates': {
          'latitude': 3.106024,
          'longitude': 101.752589,
          'address': 'Jalan 14, Cheras, KL'
        },
        'rating': 4.8,
        'reviews': 128,
      },
      {
        'id': 'mock_shop_2', 
        'name': 'Premium Barber Studio',
        'category': 'freelancer',
        'phone': '0123456789',
        'bannerImage': 'https://images.unsplash.com/photo-1585747860715-2ba37e788b70?w=400&h=250&fit=crop',
        'coordinates': {
          'latitude': 3.110000,
          'longitude': 101.750000,
          'address': 'Taman Connaught, Cheras'
        },
        'rating': 4.5,
        'reviews': 89,
      },
      {
        'id': 'mock_shop_3',
        'name': 'Urban Cuts Barbershop',
        'category': 'walk-in',
        'phone': '0178901234',
        'bannerImage': 'https://images.unsplash.com/photo-1621605815971-fbc98d665033?w=400&h=250&fit=crop',
        'coordinates': {
          'latitude': 3.102000,
          'longitude': 101.755000,
          'address': 'Taman Midah, KL'
        },
        'rating': 4.3,
        'reviews': 64,
      },
      {
        'id': 'mock_shop_4',
        'name': 'Classic Gentleman Barber',
        'category': 'walk-in+booking',
        'phone': '0198765432',
        'bannerImage': 'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=400&h=250&fit=crop',
        'coordinates': {
          'latitude': 3.108500,
          'longitude': 101.748000,
          'address': 'Taman Taynton, Cheras'
        },
        'rating': 4.9,
        'reviews': 203,
      },
    ];

    // SIMPAN SEBAGAI LIST<MAP> - NO DocumentSnapshot
    _allShops = mockShops;
    _filteredShops = mockShops;
    
    print('✅ Loaded ${_allShops.length} MOCK shops for UI testing');
    
    if (mounted) setState(() {});
  }

  // ============================================
  //  3. APPLY FILTERS (Search + Radius) - FIXED!
  // ============================================
  void _applyFilters() {
    if (_currentLocation == null) {
      _filteredShops = _allShops;
      return;
    }
    
    _filteredShops = _allShops.where((shop) {
      // shop SEKARANG adalah Map<String, dynamic>, bukan DocumentSnapshot
      
      // SEARCH FILTER
      if (_searchQuery.isNotEmpty) {
        final name = (shop['name'] ?? '').toString().toLowerCase();
        if (!name.contains(_searchQuery.toLowerCase())) return false;
      }
      
      // RADIUS FILTER
      final coords = shop['coordinates'] as Map<String, dynamic>?;
      if (coords == null) return true; // Show without distance
      
      final lat = coords['latitude'] as double?;
      final lng = coords['longitude'] as double?;
      if (lat == null || lng == null) return true;
      
      final distance = _calculateDistance(
        _currentLocation!.latitude!,
        _currentLocation!.longitude!,
        lat,
        lng,
      );
      
      return distance <= _searchRadius;
    }).toList();
    
    // Reset active index
    if (_activeShopIndex >= _filteredShops.length) {
      _activeShopIndex = 0;
    }
  }

  // ============================================
  //  4. DISTANCE CALCULATION
  // ============================================
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371e3; // Earth's radius in meters
    final lat1Rad = lat1 * pi / 180;
    final lat2Rad = lat2 * pi / 180;
    final deltaLatRad = (lat2 - lat1) * pi / 180;
    final deltaLonRad = (lon2 - lon1) * pi / 180;

    final a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
              cos(lat1Rad) * cos(lat2Rad) *
              sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
              
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Distance in meters
  }

  // ============================================
  //  5. MOVE MAP TO SHOP - FIXED!
  // ============================================
  void _moveMapToShop(Map<String, dynamic> shop, {bool animate = true}) {
    final coords = shop['coordinates'] as Map<String, dynamic>?;
    
    if (coords == null || _mapController == null) return;
    
    final lat = coords['latitude'] as double?;
    final lng = coords['longitude'] as double?;
    
    if (lat == null || lng == null) return;
    
    final cameraUpdate = CameraUpdate.newLatLngZoom(
      LatLng(lat, lng),
      16,
    );
    
    if (animate) {
      _mapController!.animateCamera(cameraUpdate);
    } else {
      _mapController!.moveCamera(cameraUpdate);
    }
  }

  // ============================================
  //  6. BUILD MARKERS - FIXED!
  // ============================================
  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    
    for (int i = 0; i < _filteredShops.length; i++) {
      final shop = _filteredShops[i];
      final coords = shop['coordinates'] as Map<String, dynamic>?;
      
      if (coords == null) continue;
      
      final lat = coords['latitude'] as double?;
      final lng = coords['longitude'] as double?;
      
      if (lat == null || lng == null) continue;
      
      final isActive = i == _activeShopIndex;
      
      markers.add(
        Marker(
          markerId: MarkerId(shop['id'] ?? 'shop_$i'),
          position: LatLng(lat, lng),
          icon: isActive
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          onTap: () {
            // ZUS Coffee Feature: Tap marker → scroll to card
            _pageController.animateToPage(
              i,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
            setState(() => _activeShopIndex = i);
            _moveMapToShop(shop);
          },
          infoWindow: InfoWindow(
            title: shop['name'] ?? 'Barbershop',
            snippet: '${shop['category'] ?? 'Haircut'} • Tap for details',
          ),
          anchor: const Offset(0.5, 1.0),
        ),
      );
    }
    
    // User location marker
    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(
            _currentLocation!.latitude!,
            _currentLocation!.longitude!,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'You are here'),
          zIndex: 2,
        ),
      );
    }
    
    return markers;
  }

  // ============================================
  //  7. BUILD SHOP CARD (ZUS Coffee Style) - FIXED!
  // ============================================
  Widget _buildShopCard(Map<String, dynamic> shop, int index) {
    final isActive = index == _activeShopIndex;
    final coords = shop['coordinates'] as Map<String, dynamic>?;
    
    // Calculate distance
    String distanceText = '';
    if (_currentLocation != null && coords != null) {
      final lat = coords['latitude'] as double?;
      final lng = coords['longitude'] as double?;
      if (lat != null && lng != null) {
        final distanceMeters = _calculateDistance(
          _currentLocation!.latitude!,
          _currentLocation!.longitude!,
          lat,
          lng,
        );
        final distanceKm = distanceMeters / 1000;
        distanceText = '${distanceKm.toStringAsFixed(1)} km';
      }
    }
    
    return GestureDetector(
      onTap: () {
        print('🏪 Selected shop: ${shop['name']}');
        // TODO: Navigate to shop detail
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        margin: EdgeInsets.symmetric(
          horizontal: 8,
          vertical: isActive ? 10 : 20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isActive ? 0.25 : 0.15),
              blurRadius: isActive ? 20 : 10,
              spreadRadius: isActive ? 0.5 : 0,
              offset: Offset(0, isActive ? 8 : 4),
            ),
          ],
          border: isActive
              ? Border.all(color: _primaryColor, width: 3)
              : null,
        ),
        child: Stack(
          children: [
            // SHOP IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 180,
                width: double.infinity,
                child: Image.network(
                  shop['bannerImage'] ?? _defaultShopImage,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Icon(Icons.storefront, size: 60, color: Colors.grey[400]),
                    );
                  },
                ),
              ),
            ),
            
            // GRADIENT OVERLAY
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                  stops: const [0.1, 0.5, 1.0],
                ),
              ),
            ),
            
            // CONTENT
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // SHOP NAME & RATING
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          shop['name']?.toString() ?? 'Barbershop',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 6,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // RATING
                      if (shop['rating'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, size: 14, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                shop['rating'].toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // CATEGORY & DISTANCE
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(shop['category']?.toString()),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (shop['category'] ?? 'walk-in').toString().toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // DISTANCE
                      if (distanceText.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, size: 12, color: Colors.red[700]),
                              const SizedBox(width: 4),
                              Text(
                                distanceText,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const Spacer(),
                      
                      // PHONE
                      if (shop['phone'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.phone, size: 12, color: Colors.green[300]),
                              const SizedBox(width: 4),
                              Text(
                                shop['phone'].toString(),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            
            // BOOK NOW BUTTON (FLOATING)
            Positioned(
              right: 16,
              top: 16,
              child: AnimatedOpacity(
                opacity: isActive ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: ElevatedButton.icon(
                  onPressed: () {
                    print('📅 Book now for: ${shop['name']}');
                    // TODO: Open booking form
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: const Text('Book Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 5,
                    shadowColor: Colors.black.withOpacity(0.4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
            
            // ACTIVE INDICATOR
            if (isActive)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: TextStyle(
                      fontSize: 10,
                      color: _primaryColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================
  //  8. HELPER: GET CATEGORY COLOR
  // ============================================
  Color _getCategoryColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'walk-in+booking':
        return Colors.green[700]!;
      case 'freelancer':
        return Colors.blue[700]!;
      case 'walk-in':
        return Colors.orange[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  // ============================================
  //  MAIN BUILD METHOD
  // ============================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Find Barbershop',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _backgroundColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // FILTER BUTTON
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (context) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Filter Options',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _backgroundColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // RADIUS SLIDER
                        Row(
                          children: [
                            Icon(Icons.my_location, color: _primaryColor),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Search Radius',
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    '${(_searchRadius / 1000).toStringAsFixed(1)} km',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: _primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        Slider(
                          value: _searchRadius,
                          min: 1000,
                          max: 20000,
                          divisions: 19,
                          activeColor: _primaryColor,
                          inactiveColor: Colors.grey[300],
                          label: '${(_searchRadius / 1000).toStringAsFixed(1)} km',
                          onChanged: (value) {
                            setState(() => _searchRadius = value);
                            _applyFilters();
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // APPLY BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _applyFilters();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: const Text(
                              'Apply Filters',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 10),
                      ],
                    ),
                  );
                },
              );
            },
            tooltip: 'Filters',
          ),
        ],
      ),
      body: _currentLocation == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _primaryColor),
                  const SizedBox(height: 20),
                  Text(
                    'Getting your location...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // FULLSCREEN MAP
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentLocation!.latitude!,
                      _currentLocation!.longitude!,
                    ),
                    zoom: 14,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  markers: _buildMarkers(),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    print('🗺️ Map controller ready');
                  },
                  onTap: (LatLng position) {
                    // Optional: Tap on map
                  },
                ),
                
                // SEARCH BAR
                Positioned(
                  top: 10,
                  left: 20,
                  right: 20,
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey[600]),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              decoration: InputDecoration(
                                hintText: 'Search barbershops...',
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey[500]),
                              ),
                              onChanged: (value) {
                                setState(() => _searchQuery = value.trim());
                                _applyFilters();
                              },
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                                _applyFilters();
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // MY LOCATION BUTTON
                Positioned(
                  bottom: 260,
                  right: 20,
                  child: FloatingActionButton.small(
                    onPressed: () {
                      if (_currentLocation != null && _mapController != null) {
                        _mapController!.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(
                              _currentLocation!.latitude!,
                              _currentLocation!.longitude!,
                            ),
                            14,
                          ),
                        );
                      }
                    },
                    backgroundColor: Colors.white,
                    foregroundColor: _primaryColor,
                    elevation: 3,
                    child: const Icon(Icons.my_location),
                  ),
                ),
                
                // HORIZONTAL CARDS (ZUS Coffee Style)
                if (_filteredShops.isNotEmpty)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    height: 240,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _filteredShops.length,
                      onPageChanged: (index) {
                        // ZUS Coffee Feature: Swipe cards → move map
                        setState(() => _activeShopIndex = index);
                        _moveMapToShop(_filteredShops[index]);
                      },
                      itemBuilder: (context, index) {
                        return _buildShopCard(_filteredShops[index], index);
                      },
                    ),
                  ),
                
                // EMPTY STATE
                if (_filteredShops.isEmpty)
                  Positioned.fill(
                    child: Center(
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_searching,
                                size: 80,
                                color: _primaryColor.withOpacity(0.7),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No barbershops found',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: _backgroundColor,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Try adjusting your search radius\nor searching with different keywords',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _searchRadius = 5000;
                                    _searchCtrl.clear();
                                    _searchQuery = '';
                                    _applyFilters();
                                  });
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Reset Filters'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _primaryColor,
                                  foregroundColor: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // SHOPS COUNTER
                if (_filteredShops.isNotEmpty)
                  Positioned(
                    top: 70,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_filteredShops.length} shops nearby',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }
}