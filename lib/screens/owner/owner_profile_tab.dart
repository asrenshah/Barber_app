import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'owner_location_manager.dart';
import 'owner_shop_header.dart';
import '../auth/profile_selector.dart';
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

  late OwnerLocationManager locationManager;
  late OwnerShopHeader shopHeader;

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
    
    shopHeader = OwnerShopHeader(
      user: user,
      shopData: shopData,
      setState: setState,
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

  // ✅ FIXED UPLOAD FUNCTION - SIMPLE VERSION
  Future<String?> _uploadImage(File imageFile, {required bool isBanner}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // ✅ SIMPLE PATH
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('shops/${user.uid}/${isBanner ? 'banner' : 'profile'}/${DateTime.now().millisecondsSinceEpoch}.jpg');

      print('📤 Uploading to: ${storageRef.fullPath}');
      
      // ✅ SIMPLE UPLOAD
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Upload success! URL: $downloadUrl');
      
      // Update Firestore
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

  // ✅ FUNCTION UNTUK PICK & UPLOAD
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

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Uploading ${isBanner ? 'banner' : 'profile'} image...'),
            ],
          ),
        ),
      );

      // Upload
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

  void _editShopInfo() async {
    TextEditingController nameCtrl = TextEditingController(text: shopData?['name'] ?? '');
    TextEditingController phoneCtrl = TextEditingController(text: shopData?['phone'] ?? '');
    TextEditingController locationCtrl = TextEditingController(text: shopData?['location'] ?? '');
    String category = shopData?['category'] ?? 'walk-in';

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
                    value: category,
                    items: const [
                      DropdownMenuItem(value: 'walk-in', child: Text('Walk-in sahaja')),
                      DropdownMenuItem(value: 'walk-in+booking', child: Text('Walk-in + booking luar')),
                      DropdownMenuItem(value: 'freelancer', child: Text('Freelancer')),
                    ],
                    onChanged: (val) {
                      setDialogState(() => category = val ?? 'walk-in');
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
                  await db.collection('shops').doc(user!.uid).set({
                    'name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'location': locationCtrl.text.trim(),
                    'category': category,
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

  void _logout() async {
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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ SHOP HEADER DENGAN PROFILE UPLOAD
            _buildShopHeader(context),
            
            const SizedBox(height: 20),
            
            // ✅ BANNER UPLOAD CARD
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.photo_size_select_actual, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text(
                          "Shop Banner",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Banner preview
                    if (shopData?['bannerImage'] != null)
                      Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(shopData!['bannerImage']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_size_select_actual, size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('No banner uploaded', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _pickAndUploadImage(isBanner: true),
                        icon: const Icon(Icons.upload, size: 18),
                        label: const Text("Upload Banner Image"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple[50],
                          foregroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.business, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text(
                          "Business Information",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    _buildInfoRow("Nama Kedai", shopData?['name'] ?? 'Belum diset'),
                    _buildInfoRow("Telefon", shopData?['phone'] ?? 'Belum diset'),
                    _buildInfoRow("Alamat", shopData?['location'] ?? 'Belum diset'),
                    _buildInfoRow("Kategori", shopData?['category'] ?? 'walk-in'),
                    
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
            ),
            
            const SizedBox(height: 20),
            
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Account",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text("Logout"),
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
            ),
          ],
        ),
      ),
    );
  }

  // ✅ SHOP HEADER DENGAN PROFILE UPLOAD
  Widget _buildShopHeader(BuildContext context) {
    final profileImage = shopData?['profileImage'];
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: profileImage != null
                      ? NetworkImage(profileImage)
                      : null,
                  child: profileImage == null
                      ? const Icon(Icons.business, size: 40, color: Colors.grey)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      onPressed: () => _pickAndUploadImage(isBanner: false),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              shopData?['name']?.isNotEmpty == true
                  ? shopData!['name']
                  : 'No Shop Name',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? 'No email',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _pickAndUploadImage(isBanner: false),
              icon: const Icon(Icons.camera_alt, size: 16),
              label: const Text('Change Profile Picture'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: BorderSide(color: AppTheme.primaryColor),
              ),
            ),
          ],
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
}