import 'dart:io'; // 🎯 TAMBAH INI!
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../auth/profile_selector.dart';
import '../../customer_app.dart';
import 'edit_profile_screen.dart';
import 'preferences_screen.dart'; 
import 'addresses_screen.dart';
import 'payment_methods_screen.dart';
import 'security_screen.dart';
import '../../widgets/profile/profile_menu_item.dart';
import '../../widgets/profile/info_card.dart';

// 🎯 INNER CLASS UNTUK PROFILE PICTURE VIEWER - TAMBAH SEBELUM _CustomerProfileScreenState
class ProfilePictureViewer extends StatelessWidget {
  final String imageUrl;
  final String userName;
  
  const ProfilePictureViewer({
    super.key,
    required this.imageUrl,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(100),
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.white, size: 50),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black.withOpacity(0.7),
        child: Text(
          userName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Map<String, dynamic> _userData = {};
  bool _loading = true;
  bool _uploadingImage = false;
  int _totalBookings = 0;
  int _favoritesCount = 0;
  int _reviewsCount = 0;
  int _points = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _goBackToFeed() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CustomerApp()),
      (route) => false,
    );
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      // 1. Load user data
      final userDoc = await _firestore.collection('users').doc(_currentUser.uid).get();
      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data()!;
          _points = _userData['loyaltyPoints'] ?? 0;
        });
      } else {
        setState(() => _loading = false);
        return;
      }

      // 2. Load all statistics
      await _loadStatisticsData();
      
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('Error loading user data: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadStatisticsData() async {
    try {
      // A. Total Bookings
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('customerId', isEqualTo: _currentUser!.uid)
          .get();
      
      // B. Favorites (jika collection wujud)
      int favoritesCount = 0;
      try {
        final favoritesSnapshot = await _firestore
            .collection('users')
            .doc(_currentUser.uid)
            .collection('favorites')
            .limit(100)
            .get();
        favoritesCount = favoritesSnapshot.size;
      } catch (e) {
        debugPrint('Favorites collection not found: $e');
      }

      // C. Reviews (jika collection wujud)
      int reviewsCount = 0;
      try {
        final reviewsSnapshot = await _firestore
            .collection('reviews')
            .where('userId', isEqualTo: _currentUser.uid)
            .limit(100)
            .get();
        reviewsCount = reviewsSnapshot.size;
      } catch (e) {
        debugPrint('Reviews collection not found: $e');
      }

      // Update state dengan REAL DATA
      setState(() {
        _totalBookings = bookingsSnapshot.size;
        _favoritesCount = favoritesCount;
        _reviewsCount = reviewsCount;
      });

    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 80,
    );

    if (image != null) {
      await _uploadProfileImage(File(image.path)); // ✅ File class dari dart:io
    }
  }

  Future<void> _uploadProfileImage(File imageFile) async { // ✅ File parameter
    setState(() => _uploadingImage = true);

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${_currentUser!.uid}.jpg');
      
      await storageRef.putFile(imageFile);
      final downloadURL = await storageRef.getDownloadURL();
      
      await _firestore.collection('users').doc(_currentUser.uid).set({
        'photoURL': downloadURL,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      setState(() {
        _userData['photoURL'] = downloadURL;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    } finally {
      setState(() => _uploadingImage = false);
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const ProfileSelector()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: () {
                  if (_userData['photoURL'] != null && !_uploadingImage) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfilePictureViewer( // ✅ Class ada sekarang
                          imageUrl: _userData['photoURL']!,
                          userName: _userData['name'] ?? 'Customer',
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: _uploadingImage
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : _userData['photoURL'] != null
                          ? CircleAvatar(
                              backgroundImage:
                                  CachedNetworkImageProvider(_userData['photoURL']!),
                            )
                          : CircleAvatar(
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                  ),
                  child: IconButton(
                    onPressed: _uploadingImage ? null : _pickImage,
                    icon: Icon(Icons.camera_alt,
                        size: 18, color: Theme.of(context).primaryColor),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _userData['name']?.isNotEmpty == true ? _userData['name'] : 'Customer',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _userData['email'] ?? _currentUser?.email ?? 'No email',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _userData['phone']?.isNotEmpty == true ? _userData['phone']! : 'No phone number',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          InfoCard(
            title: 'Total Bookings',
            value: _totalBookings.toString(),
            icon: Icons.calendar_today,
            backgroundColor: Colors.blue.withOpacity(0.1),
            iconColor: Colors.blue,
          ),
          InfoCard(
            title: 'Favorites',
            value: _favoritesCount.toString(),
            icon: Icons.favorite,
            backgroundColor: Colors.red.withOpacity(0.1),
            iconColor: Colors.red,
          ),
          InfoCard(
            title: 'Reviews',
            value: _reviewsCount.toString(),
            icon: Icons.star,
            backgroundColor: Colors.amber.withOpacity(0.1),
            iconColor: Colors.amber,
          ),
          InfoCard(
            title: 'Points',
            value: _points.toString(),
            icon: Icons.loyalty,
            backgroundColor: Colors.green.withOpacity(0.1),
            iconColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenu() {
    return Column(
      children: [
        ProfileMenuItem(
          icon: Icons.edit,
          title: 'Edit Profile',
          subtitle: 'Update your personal information',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditProfileScreen(userData: _userData),
              ),
            ).then((_) => _loadUserData());
          },
        ),
        ProfileMenuItem(
          icon: Icons.settings,
          title: 'Preferences',
          subtitle: 'Notification & booking preferences',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PreferencesScreen()),
            );
          },
        ),
        ProfileMenuItem(
          icon: Icons.location_on,
          title: 'My Addresses',
          subtitle: 'Manage saved addresses',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddressesScreen()),
            );
          },
        ),
        ProfileMenuItem(
          icon: Icons.credit_card,
          title: 'Payment Methods',
          subtitle: 'Saved cards & e-wallets',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PaymentMethodsScreen()),
            );
          },
        ),
        ProfileMenuItem(
          icon: Icons.security,
          title: 'Security',
          subtitle: 'Password & privacy settings',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SecurityScreen()),
            );
          },
        ),
        ProfileMenuItem(
          icon: Icons.help_outline,
          title: 'Help & Support',
          subtitle: 'FAQ, contact us, feedback',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Help & Support screen coming soon!')),
            );
          },
        ),
        ProfileMenuItem(
          icon: Icons.info_outline,
          title: 'About App',
          subtitle: 'Version 1.0.0 • Terms & Privacy',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('About screen coming soon!')),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _userData.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Theme.of(context).primaryColor),
              const SizedBox(height: 16),
              const Text('Loading profile...'),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        _goBackToFeed();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBackToFeed,
            tooltip: 'Back to Feed',
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _loadUserData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildProfileHeader(),
                
                // Statistics Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildStatisticsSection(),
                    ],
                  ),
                ),
                
                // Profile Menu Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildProfileMenu(),
                    ],
                  ),
                ),
                
                // Logout Button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _logout,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Logout Account',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}