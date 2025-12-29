// lib/screens/owner/profile/owner_services_manager.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerServicesManager extends StatefulWidget {
  final List<dynamic> services;
  final String userId;
  final Function onUpdate;
  
  const OwnerServicesManager({
    super.key,
    required this.services,
    required this.userId,
    required this.onUpdate,
  });
  
  @override
  State<OwnerServicesManager> createState() => _OwnerServicesManagerState();
}

class _OwnerServicesManagerState extends State<OwnerServicesManager> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  
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
                decoration: const InputDecoration(
                  labelText: 'Nama Perkhidmatan*',
                  hintText: 'Contoh: Potongan Rambut Wanita',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga (RM)*',
                  hintText: 'Contoh: 35.00',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tempoh (minit)*',
                  hintText: 'Contoh: 45',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
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
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text("Sila isi nama dan harga")));
                return;
              }

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                final newService = {
                  'id': existingService?['id'] ?? 
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  'name': nameCtrl.text.trim(),
                  'price': double.tryParse(priceCtrl.text) ?? 0.0,
                  'duration': int.tryParse(durationCtrl.text) ?? 30,
                  'description': descCtrl.text.trim(),
                };

                List<dynamic> updatedServices = 
                    List.from(widget.services);
                
                if (existingService == null) {
                  updatedServices.add(newService);
                } else if (index != null) {
                  updatedServices[index] = newService;
                }

                await db.collection('shops').doc(widget.userId).update({
                  'services': updatedServices,
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                Navigator.pop(ctx);
                
                widget.onUpdate();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(existingService == null 
                        ? "✅ Perkhidmatan ditambah!" 
                        : "✅ Perkhidmatan dikemaskini!"),
                    backgroundColor: Colors.green,
                  ),
                );
                
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("❌ Ralat: ${e.toString()}"),
                    backgroundColor: Colors.red,
                  ),
                );
                print('Error saving service: $e');
              }
            },
            child: Text(existingService == null ? "Tambah" : "Simpan"),
          ),
        ],
      ),
    );
  }

  void _deleteService(int index, String serviceId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Padam Perkhidmatan"),
        content: const Text("Adakah anda pasti mahu memadam perkhidmatan ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Padam", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        List<dynamic> updatedServices = List.from(widget.services);
        updatedServices.removeAt(index);
        
        await db.collection('shops').doc(widget.userId).update({
          'services': updatedServices,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        Navigator.pop(context);
        widget.onUpdate();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("🗑️ Perkhidmatan dipadam"),
            backgroundColor: Colors.orange,
          ),
        );
        
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Ralat memadam: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "📋 Senarai Perkhidmatan",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.deepPurple),
                  onPressed: () => _showServiceDialog(),
                  tooltip: "Tambah Perkhidmatan",
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            if (widget.services.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(Icons.list_alt, size: 50, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    const Text(
                      "Tiada perkhidmatan lagi",
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text("Tambah Perkhidmatan Pertama"),
                      onPressed: () => _showServiceDialog(),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.services.length,
                separatorBuilder: (_, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final service = widget.services[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple[50],
                      child: Text(
                        "RM${service['price']?.toStringAsFixed(0) ?? '0'}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    title: Text(service['name'] ?? ''),
                    subtitle: Text(
                      "${service['duration']} minit${service['description']?.isNotEmpty == true 
                          ? " • ${service['description']}" 
                          : ""}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () => _showServiceDialog(
                            existingService: service,
                            index: index,
                          ),
                          tooltip: "Edit",
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
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
}