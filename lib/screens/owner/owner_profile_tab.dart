import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../auth/profile_selector.dart';

// Import komponen modular dari folder profile
import './profile/owner_profile_header.dart';
import './profile/owner_contacts_manager.dart';
import './profile/owner_hours_manager.dart';
import './profile/owner_services_manager.dart';
import './profile/owner_preview_screen.dart';

// Import dari folder owner (root)
import 'owner_location_manager.dart';
import '../../theme/app_theme.dart';

class OwnerProfileTab extends StatefulWidget {
  const OwnerProfileTab({super.key});

  @override
  State<OwnerProfileTab> createState() => _OwnerProfileTabState();
}

class _OwnerProfileTabState extends State<OwnerProfileTab> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore db = FirebaseFirestore.instance;
  Map<String, dynamic>? shopData;
  bool loading = true;
  final bool _hasUnsavedChanges = false;
  late OwnerLocationManager locationManager;

  @override
  void initState() {
    super.initState();
    _loadShopData();
    _initializeManagers();
  }

  void _initializeManagers() {
    locationManager = OwnerLocationManager(
      user: user,
      db: db,
      loadShopData: _loadShopData,
    );
  }

  Future<void> _loadShopData() async {
    if (user == null) return;
    
    try {
      final doc = await db.collection('shops').doc(user!.uid).get();
      
      if (doc.exists) {
        if (mounted) {
          setState(() {
            shopData = doc.data();
            loading = false;
          });
        }
      } else {
        await db.collection('shops').doc(user!.uid).set({
          'name': '',
          'phone': '',
          'location': '',
          'coordinates': {
            'latitude': 0.0,
            'longitude': 0.0,
            'address': ''
          },
          'category': 'walk-in',
          'services': [],
          'contacts': [],
          'operatingHours': {},
          'stats': {
            'totalBookings': 0,
            'averageRating': 0.0,
            'followerCount': 0
          },
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        final newDoc = await db.collection('shops').doc(user!.uid).get();
        if (mounted) {
          setState(() {
            shopData = newDoc.data();
            loading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading shop data: $e');
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<String?> _uploadImage(File imageFile, {required bool isBanner}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('shops/${user.uid}/${isBanner ? 'banner' : 'profile'}/${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      await FirebaseFirestore.instance
          .collection('shops')
          .doc(user.uid)
          .update({
            '${isBanner ? 'banner' : 'profile'}Image': downloadUrl,
            '${isBanner ? 'banner' : 'profile'}ImageUpdated': FieldValue.serverTimestamp(),
          });

      return downloadUrl;
      
    } catch (e) {
      print('❌ Upload error: $e');
      return null;
    }
  }

  Future<void> _pickAndUploadImage({required bool isBanner}) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: isBanner ? 1200 : 800,
        maxHeight: isBanner ? 400 : 800,
        imageQuality: isBanner ? 90 : 85,
      );

      if (pickedFile == null) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text('Uploading ${isBanner ? 'banner' : 'profile'} image...'),
            ],
          ),
        ),
      );

      final imageFile = File(pickedFile.path);
      final imageUrl = await _uploadImage(imageFile, isBanner: isBanner);

      Navigator.pop(context);

      if (imageUrl != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${isBanner ? 'Banner' : 'Profile'} image uploaded!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadShopData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to upload ${isBanner ? 'banner' : 'profile'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.visibility),
        label: const Text('Lihat Sebagai Pelanggan'),
        onPressed: _viewAsCustomer,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  void _viewAsCustomer() {
    if (shopData == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OwnerPreviewScreen(
          shopData: shopData!,
          onBack: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Belum diset',
              style: TextStyle(
                color: value.isNotEmpty ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.business, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  "Maklumat Perniagaan",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow("Nama Kedai", shopData?['name']?.toString() ?? 'Belum diset'),
            _buildInfoRow("Telefon", shopData?['phone']?.toString() ?? 'Belum diset'),
            _buildInfoRow("Alamat", shopData?['location']?.toString() ?? 'Belum diset'),
            _buildInfoRow("Kategori", shopData?['category']?.toString() ?? 'walk-in'),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _editShopInfo,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text("Edit Maklumat"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                locationManager.buildLocationButton(context, shopData),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _editShopInfo() async {
    TextEditingController nameCtrl = TextEditingController(text: shopData?['name'] ?? '');
    TextEditingController phoneCtrl = TextEditingController(text: shopData?['phone'] ?? '');
    TextEditingController locationCtrl = TextEditingController(text: shopData?['location'] ?? '');
    
    String getValidCategory() {
      String currentCat = shopData?['category']?.toString() ?? 'walk-in';
      if (currentCat != 'walk-in' && 
          currentCat != 'walk-in+booking' && 
          currentCat != 'freelancer') {
        return 'walk-in';
      }
      return currentCat;
    }
    
    String category = getValidCategory();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.edit, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text("Edit Maklumat Kedai"),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Kedai',
                      hintText: 'Masukkan nama kedai',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Telefon',
                      hintText: 'Contoh: 012-3456789',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: locationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Alamat',
                      hintText: 'Alamat lengkap kedai',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category.isNotEmpty ? category : 'walk-in',
                    items: const [
                      DropdownMenuItem(value: 'walk-in', child: Text('Walk-in sahaja')),
                      DropdownMenuItem(value: 'walk-in+booking', child: Text('Walk-in + booking luar')),
                      DropdownMenuItem(value: 'freelancer', child: Text('Freelancer')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => category = val);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Kategori Perniagaan',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final validCategory = category.isNotEmpty ? category : 'walk-in';
                  
                  await db.collection('shops').doc(user!.uid).set({
                    'name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'location': locationCtrl.text.trim(),
                    'category': validCategory,
                    'updatedAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));

                  _loadShopData();
                  Navigator.pop(ctx);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Maklumat kedai berjaya dikemaskini!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text("Simpan"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogoutCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Akaun",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text("Log Keluar"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Keluar'),
        content: const Text('Adakah anda pasti ingin log keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
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
            child: const Text('Log Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Profile & Settings"),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile & Settings"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            OwnerProfileHeader(
              shopData: shopData,
              onImagePick: (isBanner) => _pickAndUploadImage(isBanner: isBanner),
            ),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 20),
            _buildBasicInfoCard(),
            const SizedBox(height: 20),
            OwnerHoursManager(
              hours: shopData?['operatingHours'] ?? {},
              userId: user!.uid,
              onUpdate: _loadShopData,
            ),
            const SizedBox(height: 20),
            OwnerContactsManager(
              contacts: shopData?['contacts'] ?? [],
              userId: user!.uid,
              onUpdate: _loadShopData,
            ),
            const SizedBox(height: 20),
            OwnerServicesManager(
              services: shopData?['services'] ?? [],
              userId: user!.uid,
              onUpdate: _loadShopData,
            ),
            const SizedBox(height: 20),
            _buildLogoutCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}