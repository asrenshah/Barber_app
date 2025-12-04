import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'owner_location_manager.dart';
import 'owner_shop_header.dart';
import '../auth/profile_selector.dart';


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

  // ✅ SENARAI HARI UNTUK WAKTU OPERASI
  final List<Map<String, String>> _days = [
    {'en': 'Monday', 'ms': 'Isnin'},
    {'en': 'Tuesday', 'ms': 'Selasa'},
    {'en': 'Wednesday', 'ms': 'Rabu'},
    {'en': 'Thursday', 'ms': 'Khamis'},
    {'en': 'Friday', 'ms': 'Jumaat'},
    {'en': 'Saturday', 'ms': 'Sabtu'},
    {'en': 'Sunday', 'ms': 'Ahad'},
  ];

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
          'services': [], // ✅ DITAMBAH: senarai perkhidmatan
          'contacts': [], // ✅ DITAMBAH: senarai hubungan
          'operatingHours': {}, // ✅ DITAMBAH: waktu operasi
          'stats': { // ✅ DITAMBAH: statistik
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

  // ✅ FUNGSI UPLOAD GAMBAR (TETAP SAMA)
  Future<String?> _uploadImage(File imageFile, {required bool isBanner}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('shops/${user.uid}/${isBanner ? 'banner' : 'profile'}/${DateTime.now().millisecondsSinceEpoch}.jpg');

      print('📤 Uploading to: ${storageRef.fullPath}');
      
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ Upload success! URL: $downloadUrl');
      
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

  // ✅ FUNGSI UNTUK PICK & UPLOAD (TETAP SAMA)
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
              CircularProgressIndicator(),
              SizedBox(height: 12),
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

  // ===============================
  // ✅ BAHAGIAN 1: HEADER FACEBOOK-STYLE
  // ===============================
  Widget _buildFacebookStyleHeader() {
    final bannerUrl = shopData?['bannerImage'];
    final profileUrl = shopData?['profileImage'];
    
    return Container(
      height: 220,
      child: Stack(
        children: [
          // BANNER
          GestureDetector(
            onTap: () => _pickAndUploadImage(isBanner: true),
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                image: bannerUrl != null ? DecorationImage(
                  image: CachedNetworkImageProvider(bannerUrl),
                  fit: BoxFit.cover,
                ) : null,
              ),
              child: bannerUrl == null ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[600]),
                    SizedBox(height: 8),
                    Text('Klik untuk tambah banner', style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
              ) : null,
            ),
          ),
          
          // GAMBAR PROFIL (di atas banner)
          Positioned(
            bottom: 0,
            left: 16,
            child: GestureDetector(
              onTap: () => _pickAndUploadImage(isBanner: false),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black26)],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: profileUrl != null 
                      ? CachedNetworkImageProvider(profileUrl)
                      : null,
                  child: profileUrl == null 
                      ? Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
              ),
            ),
          ),
          
          // STATISTIK RINGKAS (Chips)
          Positioned(
            bottom: 10,
            right: 16,
            child: Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text('${shopData?['stats']?['totalBookings'] ?? 0} Tempahan'),
                  backgroundColor: Colors.deepPurple.withOpacity(0.1),
                ),
                Chip(
                  label: Text('⭐ ${shopData?['stats']?['averageRating']?.toStringAsFixed(1) ?? '0.0'}'),
                  backgroundColor: Colors.amber.withOpacity(0.1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // ✅ BAHAGIAN 2: SISTEM HUBUNGAN PINTAR
  // ===============================
  void _launchContact(String number, String type) async {
    final url = type == 'whatsapp' 
        ? 'https://wa.me/6$number'  // '6' untuk Malaysia
        : 'tel:$number';
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak boleh buka: $e')));
    }
  }

  Widget _buildContactSection() {
    final contacts = shopData?['contacts'] ?? [];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_phone, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text('Hubungan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.add, size: 20),
                  onPressed: _addContact,
                  tooltip: 'Tambah Nombor',
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            if (contacts.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(Icons.phone_disabled, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Tiada nombor hubungan ditambah'),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('Tambah Nombor Pertama'),
                      onPressed: _addContact,
                    ),
                  ],
                ),
              )
            else
              Column(
                children: contacts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final contact = entry.value;
                  return ListTile(
                    leading: Icon(contact['type'] == 'whatsapp' 
                        ? Icons.chat_bubble 
                        : Icons.phone,
                        color: contact['type'] == 'whatsapp' ? Colors.green : Colors.blue),
                    title: Text(contact['label'] ?? 'Nombor'),
                    subtitle: Text(contact['number']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, size: 18),
                          onPressed: () => _editContact(index, contact),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, size: 18, color: Colors.red),
                          onPressed: () => _deleteContact(index),
                        ),
                      ],
                    ),
                    onTap: () => _launchContact(contact['number'], contact['type']),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  // ✅ FUNGSI BANTUAN UNTUK HUBUNGAN (SIMPAN DULU)
  void _addContact() {
    // Anda boleh implement dialog di sini
    print('Tambah hubungan');
  }

  void _editContact(int index, Map<String, dynamic> contact) {
    print('Edit hubungan: $index');
  }

  void _deleteContact(int index) {
    print('Padam hubungan: $index');
  }

  // ===============================
  // ✅ BAHAGIAN 3: WAKTU OPERASI
  // ===============================
  Widget _buildOperatingHours() {
    final hours = shopData?['operatingHours'] ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text('Waktu Operasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.edit, size: 20),
                  onPressed: _editOperatingHours,
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            Column(
              children: _days.map((day) {
                final dayHours = hours[day['en']];
                final isOpen = dayHours != null && dayHours['open'] != null;
                
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: SizedBox(width: 80, child: Text(day['ms'] ?? '')),
                  title: isOpen 
                      ? Text('${dayHours['open']} - ${dayHours['close']}')
                      : Text('Tutup', style: TextStyle(color: Colors.grey)),
                  trailing: Icon(isOpen ? Icons.check_circle : Icons.cancel, 
                      color: isOpen ? Colors.green : Colors.grey, size: 18),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _editOperatingHours() {
    print('Edit waktu operasi');
  }

  // ===============================
  // ✅ BAHAGIAN 4: PENGURUSAN PERKHIDMATAN
  // ===============================
  void _showServiceDialog({Map<String, dynamic>? existingService, int? index}) {
    TextEditingController nameCtrl = TextEditingController(
        text: existingService?['name'] ?? '');
    TextEditingController priceCtrl = TextEditingController(
        text: existingService?['price']?.toString() ?? '');
    TextEditingController durationCtrl = TextEditingController(
        text: existingService?['duration']?.toString() ?? '30');
    TextEditingController descCtrl = TextEditingController(
        text: existingService?['description'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existingService == null 
            ? "Tambah Perkhidmatan" 
            : "Edit Perkhidmatan"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Perkhidmatan*',
                  hintText: 'Contoh: Potongan Rambut Wanita',
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Harga (RM)*',
                  hintText: 'Contoh: 35.00',
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: durationCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Tempoh (minit)*',
                  hintText: 'Contoh: 45',
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(
                  labelText: 'Keterangan (pilihan)',
                  hintText: 'Terangkan perkhidmatan ini',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text("Sila isi nama dan harga")));
                return;
              }

              final newService = {
                'id': existingService?['id'] ?? 
                    DateTime.now().millisecondsSinceEpoch.toString(),
                'name': nameCtrl.text.trim(),
                'price': double.tryParse(priceCtrl.text) ?? 0.0,
                'duration': int.tryParse(durationCtrl.text) ?? 30,
                'description': descCtrl.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              };

              List<dynamic> updatedServices = 
                  List.from(shopData?['services'] ?? []);
              
              if (existingService == null) {
                updatedServices.add(newService);
              } else if (index != null) {
                updatedServices[index] = newService;
              }

              await db.collection('shops').doc(user!.uid).update({
                'services': updatedServices,
                'updatedAt': FieldValue.serverTimestamp(),
              });

              _loadShopData();
              Navigator.pop(ctx);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(existingService == null 
                      ? "✅ Perkhidmatan ditambah!" 
                      : "✅ Perkhidmatan dikemaskini!"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(existingService == null ? "Tambah" : "Simpan"),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    final services = shopData?['services'] ?? [];
    
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "📋 Senarai Perkhidmatan",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: Colors.deepPurple),
                  onPressed: () => _showServiceDialog(),
                  tooltip: "Tambah Perkhidmatan",
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            if (services.isEmpty)
              Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.list_alt, size: 50, color: Colors.grey[400]),
                    SizedBox(height: 8),
                    Text(
                      "Tiada perkhidmatan lagi",
                      style: TextStyle(color: Colors.grey),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text("Tambah Perkhidmatan Pertama"),
                      onPressed: () => _showServiceDialog(),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: services.length,
                separatorBuilder: (_, i) => Divider(height: 1),
                itemBuilder: (context, index) {
                  final service = services[index];
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 4),
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple[50],
                      child: Text(
                        "RM${service['price']?.toStringAsFixed(0) ?? '0'}",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    title: Text(service['name'] ?? ''),
                    subtitle: Text(
                      "${service['duration']} minit"
                      + (service['description']?.isNotEmpty == true 
                          ? " • ${service['description']}" 
                          : ""),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, size: 20),
                          onPressed: () => _showServiceDialog(
                            existingService: service,
                            index: index,
                          ),
                          tooltip: "Edit",
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () => _deleteService(index, service['id']),
                          tooltip: "Padam",
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _deleteService(int index, String serviceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Padam Perkhidmatan"),
        content: Text("Adakah anda pasti mahu memadam perkhidmatan ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("Padam", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      List<dynamic> updatedServices = List.from(shopData?['services'] ?? []);
      updatedServices.removeAt(index);
      
      await db.collection('shops').doc(user!.uid).update({
        'services': updatedServices,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      _loadShopData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🗑️ Perkhidmatan dipadam"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // ===============================
  // ✅ BAHAGIAN 5: BUTANG TINDAKAN
  // ===============================
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.edit),
              label: Text('Edit Maklumat Kedai'),
              onPressed: _editShopInfo,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: Icon(Icons.visibility),
              label: Text('Lihat Sebagai Pelanggan'),
              onPressed: () {
                // Akan diimplementasi kemudian
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Fitur ini akan datang')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
                padding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // ✅ BAHAGIAN 6: MAKLUMAT ASAS (dari kod asal, diubahsuai)
  // ===============================
  Widget _buildBasicInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  "Maklumat Perniagaan",
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
    );
  }

  // ✅ FUNGSI EDIT MAKLUMAT KEDAI (dari kod asal)
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

  // ===============================
  // ✅ BAHAGIAN 7: LOGOUT (dari kod asal)
  // ===============================
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

  // ===============================
  // ✅ WIDGET PEMBANTU
  // ===============================
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

  // ===============================
  // ✅ BUILD METHOD UTAMA
  // ===============================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HEADER FACEBOOK-STYLE
            _buildFacebookStyleHeader(),
            
            SizedBox(height: 16),
            
            // 2. BUTANG TINDAKAN
            _buildActionButtons(),
            
            SizedBox(height: 16),
            
            // 3. MAKLUMAT ASAS
            _buildBasicInfoCard(),
            
            SizedBox(height: 16),
            
            // 4. WAKTU OPERASI
            _buildOperatingHours(),
            
            SizedBox(height: 16),
            
            // 5. HUBUNGAN
            _buildContactSection(),
            
            SizedBox(height: 16),
            
            // 6. PENGURUSAN PERKHIDMATAN
            _buildServicesSection(),
            
            SizedBox(height: 16),
            
            // 7. LOGOUT
            _buildLogoutCard(),
            
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}