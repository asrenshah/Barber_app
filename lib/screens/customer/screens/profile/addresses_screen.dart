import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  List<Map<String, dynamic>> _addresses = [];
  bool _loading = true;
  
  // Key untuk simpan di SharedPreferences
  static const String _addressesKey = 'customer_addresses';
  
  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }
  
  // Load dari Local Storage (SharedPreferences)
  Future<void> _loadAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = prefs.getString(_addressesKey);
      
      if (addressesJson != null) {
        final List<dynamic> addressesList = json.decode(addressesJson);
        setState(() {
          _addresses = addressesList.map((item) => Map<String, dynamic>.from(item)).toList();
        });
      }
    } catch (e) {
      print('Error loading addresses: $e');
    } finally {
      setState(() => _loading = false);
    }
  }
  
  // Save ke Local Storage (SharedPreferences)
  Future<void> _saveAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = json.encode(_addresses);
      await prefs.setString(_addressesKey, addressesJson);
    } catch (e) {
      print('Error saving addresses: $e');
    }
  }
  
  // Delete address
  Future<void> _deleteAddress(int index) async {
    setState(() {
      _addresses.removeAt(index);
    });
    await _saveAddresses();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address deleted'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  // Set default address
  Future<void> _setDefaultAddress(int index) async {
    setState(() {
      // Reset semua ke false
      for (var address in _addresses) {
        address['isDefault'] = false;
      }
      // Set selected ke true
      _addresses[index]['isDefault'] = true;
    });
    await _saveAddresses();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Default address updated'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  // Navigate ke Add Address
  void _navigateToAddAddress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAddressScreen(
          onAddressAdded: (newAddress) async {
            // Add ke local list
            setState(() => _addresses.add(newAddress));
            await _saveAddresses();
          },
        ),
      ),
    );
  }
  
  Widget _buildAddressCard(Map<String, dynamic> address, int index) {
    final isDefault = address['isDefault'] == true;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDefault ? Colors.blue : Colors.grey.shade200,
          width: isDefault ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'DEFAULT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.grey, size: 20),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (context) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.star, color: Colors.amber),
                                title: const Text('Set as Default'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _setDefaultAddress(index);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.delete, color: Colors.red),
                                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                                onTap: () {
                                  Navigator.pop(context);
                                  _deleteAddress(index);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.close),
                                title: const Text('Cancel'),
                                onTap: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              address['label'] ?? 'Address',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              address['addressLine1'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            if (address['addressLine2'] != null && address['addressLine2'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  address['addressLine2'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${address['postcode'] ?? ''} ${address['city'] ?? ''}, ${address['state'] ?? ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'No Addresses',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Add your addresses for your reference',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton.icon(
                        onPressed: _navigateToAddAddress,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Address'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAddresses,
                  child: ListView.builder(
                    itemCount: _addresses.length,
                    itemBuilder: (context, index) {
                      return _buildAddressCard(_addresses[index], index);
                    },
                  ),
                ),
      floatingActionButton: _addresses.isNotEmpty
          ? FloatingActionButton(
              onPressed: _navigateToAddAddress,
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              mini: true,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

// ============================================
// SIMPLE ADD ADDRESS SCREEN (LOCAL ONLY)
// ============================================

class AddAddressScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddressAdded;
  
  const AddAddressScreen({
    super.key,
    required this.onAddressAdded,
  });

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Simple form fields
  String _label = 'Home';
  String _addressLine1 = '';
  String _addressLine2 = '';
  String _city = '';
  String _state = '';
  String _postcode = '';
  
  final List<String> _addressLabels = ['Home', 'Work', 'Other'];
  final List<String> _malaysianStates = [
    'Johor', 'Kedah', 'Kelantan', 'Melaka', 'Negeri Sembilan',
    'Pahang', 'Perak', 'Perlis', 'Pulau Pinang', 'Sabah',
    'Sarawak', 'Selangor', 'Terengganu', 'Wilayah Persekutuan Kuala Lumpur',
    'Wilayah Persekutuan Labuan', 'Wilayah Persekutuan Putrajaya'
  ];
  
  void _saveAddress() {
    if (!_formKey.currentState!.validate()) return;
    
    final newAddress = {
      'label': _label,
      'addressLine1': _addressLine1,
      'addressLine2': _addressLine2,
      'city': _city,
      'state': _state,
      'postcode': _postcode,
      'isDefault': false, // Default false, boleh set kemudian
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    widget.onAddressAdded(newAddress);
    Navigator.pop(context);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Address'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              const Text('Address Label', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _label,
                items: _addressLabels.map((label) {
                  return DropdownMenuItem(
                    value: label,
                    child: Text(label),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _label = value!),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Address Line 1
              const Text('Address Line 1', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'e.g., No 123, Jalan Merdeka',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter address';
                  return null;
                },
                onChanged: (value) => _addressLine1 = value,
              ),
              
              const SizedBox(height: 16),
              
              // Address Line 2 (Optional)
              const Text('Address Line 2 (Optional)', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'e.g., Apartment, Building, etc.',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (value) => _addressLine2 = value,
              ),
              
              const SizedBox(height: 16),
              
              // City
              const Text('City/Town', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  hintText: 'e.g., Kuala Lumpur',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter city';
                  return null;
                },
                onChanged: (value) => _city = value,
              ),
              
              const SizedBox(height: 16),
              
              // State & Postcode Row
              Row(
                children: [
                  // State
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('State', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _state.isNotEmpty ? _state : null,
                          items: _malaysianStates.map((state) {
                            return DropdownMenuItem(
                              value: state,
                              child: Text(state),
                            );
                          }).toList(),
                          onChanged: (value) => setState(() => _state = value!),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            hintText: 'Select state',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Select state';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Postcode
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Postcode', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'e.g., 50000',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter postcode';
                            if (value.length != 5) return '5 digits required';
                            return null;
                          },
                          onChanged: (value) => _postcode = value,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save Address',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Address is saved locally on this device only for your reference',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}