// lib/screens/owner/owner_services_manager.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerServicesManager {
  final User? user;
  final FirebaseFirestore db;
  
  OwnerServicesManager({
    required this.user,
    required this.db,
  });

  void addService(BuildContext context) async {
    TextEditingController nameCtrl = TextEditingController();
    TextEditingController priceCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tambah Servis"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Servis')),
            TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Harga')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final serviceRef = db.collection('shops').doc(user!.uid).collection('services');
              await serviceRef.add({
                'name': nameCtrl.text.trim(),
                'price': double.tryParse(priceCtrl.text.trim()) ?? 0,
                'createdAt': Timestamp.now(),
              });
              Navigator.pop(ctx);
            },
            child: const Text("Tambah"),
          ),
        ],
      ),
    );
  }

  void addStaff(BuildContext context) async {
    TextEditingController nameCtrl = TextEditingController();
    TextEditingController roleCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tambah Staff"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Staff')),
            TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'Jawatan')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final staffRef = db.collection('shops').doc(user!.uid).collection('staff');
              await staffRef.add({
                'name': nameCtrl.text.trim(),
                'role': roleCtrl.text.trim(),
                'createdAt': Timestamp.now(),
              });
              Navigator.pop(ctx);
            },
            child: const Text("Tambah"),
          ),
        ],
      ),
    );
  }

  void deleteItem(BuildContext context, String type, String id) async {
    await db.collection('shops').doc(user!.uid).collection(type).doc(id).delete();
  }

  Widget buildServicesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Services StreamBuilder
        const Text("Servis Anda", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Senarai servis"),
            IconButton(onPressed: () => addService(context), icon: const Icon(Icons.add)),
          ],
        ),
        StreamBuilder<QuerySnapshot>(
          stream: db.collection('shops').doc(user!.uid).collection('services').snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Text("Loading...");
            final docs = snap.data!.docs;
            if (docs.isEmpty) return const Text("Tiada servis lagi");
            return Column(
              children: docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(data['name'] ?? ''),
                    subtitle: Text("Harga: RM${data['price'] ?? 0}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteItem(context, 'services', d.id),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),

        const SizedBox(height: 24),

        // Staff StreamBuilder
        const Text("Staff Anda", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Senarai staff"),
            IconButton(onPressed: () => addStaff(context), icon: const Icon(Icons.add)),
          ],
        ),
        StreamBuilder<QuerySnapshot>(
          stream: db.collection('shops').doc(user!.uid).collection('staff').snapshots(),
          builder: (ctx, snap) {
            if (!snap.hasData) return const Text("Loading...");
            final docs = snap.data!.docs;
            if (docs.isEmpty) return const Text("Tiada staff lagi");
            return Column(
              children: docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(data['name'] ?? ''),
                    subtitle: Text(data['role'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteItem(context, 'staff', d.id),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}