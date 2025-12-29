// lib/screens/shared/universal_profile_form.dart - SYNC WITH OWNER PROFILE
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

// Import screens - PATHS FIXED
import 'location_picker_screen.dart';
import '../owner/owner_dashboard.dart';
import '../customer/customer_app.dart';

class UniversalProfileForm extends StatefulWidget {
  final String mode; // 'create', 'edit', 'google-first-time'
  final String userType; // 'customer', 'owner'
  final Map<String, dynamic>? initialData;
  
  const UniversalProfileForm({
    super.key,
    required this.mode,
    required this.userType,
    this.initialData,
  });

  @override
  State<UniversalProfileForm> createState() => _UniversalProfileFormState();
}

class _UniversalProfileFormState extends State<UniversalProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController(); // ⬅️ NAME CHANGED: shopAddress → location
  final TextEditingController _categoryController = TextEditingController(); // ⬅️ NAME CHANGED: shopCategory → category
  
  bool _loading = false;
  bool _isOwner = false;
  
  // AUTO-SAVE SYSTEM
  bool _autoSaving = false;
  Timer? _autoSaveTimer;
  bool _hasUserTyped = false;

  @override
  void initState() {
    super.initState();
    _isOwner = widget.userType.toLowerCase().contains('owner') || 
                widget.userType.toLowerCase().contains('shop');
    
    // AUTO-FILL DATA DARI INITIALDATA (SYNC DENGAN OWNER PROFILE)
    if (widget.initialData != null) {
      _nameController.text = widget.initialData?['name'] ?? '';
      _usernameController.text = widget.initialData?['username'] ?? '';
      _emailController.text = widget.initialData?['email'] ?? '';
      _phoneController.text = widget.initialData?['phone'] ?? '';
      _shopNameController.text = widget.initialData?['shopName'] ?? widget.initialData?['name'] ?? '';
      _locationController.text = widget.initialData?['location'] ?? widget.initialData?['shopAddress'] ?? ''; // ⬅️ SYNC FIELD
      _categoryController.text = widget.initialData?['category'] ?? widget.initialData?['shopCategory'] ?? 'walk-in'; // ⬅️ SYNC FIELD
    }
    
    // AUTO-FILL EMAIL DARI GOOGLE USER
    if (widget.mode == 'google-first-time') {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        _emailController.text = user.email!;
        _nameController.text = user.displayName ?? '';
      }
    }
    
    // SETUP AUTO-SAVE LISTENERS
    _setupAutoSaveListeners();
    _checkExistingData();
  }

  void _checkExistingData() {
    final hasExistingData = _nameController.text.isNotEmpty ||
                           _usernameController.text.isNotEmpty ||
                           _phoneController.text.isNotEmpty ||
                           _shopNameController.text.isNotEmpty ||
                           _locationController.text.isNotEmpty;
    
    if (hasExistingData) {
      _hasUserTyped = true;
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _shopNameController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _setupAutoSaveListeners() {
    _nameController.addListener(() {
      _hasUserTyped = true;
      _scheduleAutoSave();
    });
    _usernameController.addListener(() {
      _hasUserTyped = true;
      _scheduleAutoSave();
    });
    _emailController.addListener(() {
      _hasUserTyped = true;
      _scheduleAutoSave();
    });
    _phoneController.addListener(() {
      _hasUserTyped = true;
      _scheduleAutoSave();
    });
    _shopNameController.addListener(() {
      _hasUserTyped = true;
      _scheduleAutoSave();
    });
    _locationController.addListener(() {
      _hasUserTyped = true;
      _scheduleAutoSave();
    });
    _categoryController.addListener(() {
      _hasUserTyped = true;
      _scheduleAutoSave();
    });
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _performAutoSave);
  }

  // ⬅️ AUTO-SAVE: SYNC DENGAN OWNER PROFILE STRUCTURE
  Future<void> _performAutoSave() async {
    if (_autoSaving) return;
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final hasData = _nameController.text.isNotEmpty ||
                    _usernameController.text.isNotEmpty ||
                    _phoneController.text.isNotEmpty ||
                    _shopNameController.text.isNotEmpty ||
                    _locationController.text.isNotEmpty;

    if (!hasData) return;

    setState(() => _autoSaving = true);

    try {
      final userData = {
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _isOwner ? 'owner' : 'customer',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // ⬅️ SYNC KEY: 'location' dan 'category' (SAMA DENGAN OWNER PROFILE)
      if (_isOwner) {
        userData.addAll({
          'shopName': _shopNameController.text.trim(),
          'location': _locationController.text.trim(), // ✅ SYNC KEY
          'category': _categoryController.text.trim(), // ✅ SYNC KEY
        });

        // ⬅️ SAVE KE SHOPS COLLECTION (SAMA STRUCTURE DENGAN OWNER PROFILE)
        await FirebaseFirestore.instance.collection('shops').doc(user.uid).set({
          'name': _shopNameController.text.trim(),
          'location': _locationController.text.trim(), // ✅ SYNC KEY
          'category': _categoryController.text.trim(), // ✅ SYNC KEY
          'phone': _phoneController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true));

      print('✅ AUTO-SAVE BERJAYA: Data sync dengan owner profile');

    } catch (e) {
      print('❌ AUTO-SAVE ERROR: $e');
    } finally {
      setState(() => _autoSaving = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (_hasUserTyped) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final userRole = userDoc.data()?['role'] ?? 'customer';
        
        if (userRole == 'owner') {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const OwnerDashboard()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const CustomerApp()),
            (route) => false,
          );
        }
      }
      return false;
    }
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CustomerApp()),
      (route) => false,
    );
    return false;
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
    );
    
    if (result != null) {
      setState(() {
        _locationController.text = result['address']; // ⬅️ SYNC FIELD
        _hasUserTyped = true;
      });
    }
  }

  // ⬅️ SAVE PROFILE: SYNC DENGAN OWNER PROFILE
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null && widget.mode != 'create') {
        throw Exception("Tiada pengguna log masuk");
      }

      final userData = {
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': widget.userType,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // ⬅️ SYNC DENGAN OWNER PROFILE STRUCTURE
      if (_isOwner) {
        userData.addAll({
          'shopName': _shopNameController.text.trim(),
          'location': _locationController.text.trim(), // ✅ SYNC KEY
          'category': _categoryController.text.trim(), // ✅ SYNC KEY
        });
        
        // ⬅️ SAVE KE SHOPS COLLECTION (SAMA STRUCTURE)
        await FirebaseFirestore.instance.collection('shops').doc(user?.uid).set({
          'name': _shopNameController.text.trim(),
          'location': _locationController.text.trim(), // ✅ SYNC KEY
          'category': _categoryController.text.trim(), // ✅ SYNC KEY
          'phone': _phoneController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      if (widget.mode == 'create') {
        final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        await FirebaseFirestore.instance
            .collection('users')
            .doc(cred.user!.uid)
            .set(userData, SetOptions(merge: true));
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .set(userData, SetOptions(merge: true));
      }

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berjaya disimpan!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // REDIRECT BASED ON ROLE
      if (_isOwner) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OwnerDashboard()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const CustomerApp()),
          (route) => false,
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.mode == 'create' ? 'Daftar Akaun' : 
            widget.mode == 'google-first-time' ? 'Lengkapkan Profil' : 'Edit Profil',
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _onWillPop();
            },
          ),
          actions: [
            if (_autoSaving)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                if (widget.mode == 'create' || widget.mode == 'google-first-time')
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Data anda disimpan automatik semasa anda mengisi',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const Text(
                  'Maklumat Peribadi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Penuh',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Sila masukkan nama penuh';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Sila masukkan username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  readOnly: widget.mode == 'google-first-time' || widget.mode == 'edit',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Sila masukkan email';
                    }
                    if (!value.contains('@')) {
                      return 'Email tidak sah';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Nombor Telefon',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Sila masukkan nombor telefon';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                if (widget.mode == 'create') ...[
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Kata Laluan',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Sila masukkan kata laluan';
                      }
                      if (value.length < 6) {
                        return 'Minimum 6 aksara';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                
                if (_isOwner) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Maklumat Kedai (Sync dengan Owner Profile)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _shopNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Kedai',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_isOwner && (value == null || value.isEmpty)) {
                        return 'Sila masukkan nama kedai';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _locationController, // ⬅️ SYNC FIELD
                          decoration: const InputDecoration(
                            labelText: 'Alamat Kedai',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                          validator: (value) {
                            if (_isOwner && (value == null || value.isEmpty)) {
                              return 'Sila masukkan alamat kedai';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _pickLocation,
                        icon: const Icon(Icons.location_on),
                        tooltip: 'Pilih Lokasi di Peta',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  DropdownButtonFormField<String>(
                    initialValue: _categoryController.text.isEmpty 
                        ? 'walk-in' 
                        : _categoryController.text,
                    items: const [
                      DropdownMenuItem(value: 'walk-in', child: Text('Walk-in sahaja')),
                      DropdownMenuItem(value: 'walk-in+booking', child: Text('Walk-in + booking luar')),
                      DropdownMenuItem(value: 'freelancer', child: Text('Freelancer')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _categoryController.text = value ?? 'walk-in';
                        _hasUserTyped = true;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Kategori Perniagaan',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            widget.mode == 'create' ? 'Daftar' : 
                            widget.mode == 'google-first-time' ? 'Simpan Profil' : 'Kemaskini',
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}