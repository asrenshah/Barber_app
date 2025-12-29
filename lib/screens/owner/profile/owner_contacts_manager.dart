// lib/screens/owner/profile/owner_contacts_manager.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class OwnerContactsManager extends StatefulWidget {
  final List<dynamic> contacts;
  final String userId;
  final Function onUpdate;
  
  const OwnerContactsManager({
    super.key,
    required this.contacts,
    required this.userId,
    required this.onUpdate,
  });
  
  @override
  State<OwnerContactsManager> createState() => _OwnerContactsManagerState();
}

class _OwnerContactsManagerState extends State<OwnerContactsManager> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  
  void _launchContact(String number, String type) async {
    final url = type == 'whatsapp' 
        ? 'https://wa.me/6$number'
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

  void _showAddContactDialog() async {
    TextEditingController labelCtrl = TextEditingController();
    TextEditingController numberCtrl = TextEditingController();
    String contactType = 'phone';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Tambah Hubungan Baru"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Label (cth: Telefon Utama)',
                    hintText: 'Masukkan label',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: numberCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nombor Telefon',
                    hintText: 'Contoh: 0123456789',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: contactType,
                  items: const [
                    DropdownMenuItem(value: 'phone', child: Text('Panggilan Telefon')),
                    DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
                  ],
                  onChanged: (val) {
                    setDialogState(() => contactType = val ?? 'phone');
                  },
                  decoration: const InputDecoration(labelText: 'Jenis Hubungan'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (labelCtrl.text.isEmpty || numberCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text("Sila isi semua maklumat")));
                    return;
                  }

                  List<dynamic> updatedContacts = List.from(widget.contacts);
                  updatedContacts.add({
                    'label': labelCtrl.text.trim(),
                    'number': numberCtrl.text.trim(),
                    'type': contactType,
                    'isActive': true,
                  });

                  await db.collection('shops').doc(widget.userId).update({
                    'contacts': updatedContacts,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  widget.onUpdate();
                  Navigator.pop(ctx);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Hubungan berjaya ditambah!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text("Tambah"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditContactDialog(int index, Map<String, dynamic> contact) async {
    TextEditingController labelCtrl = TextEditingController(text: contact['label']);
    TextEditingController numberCtrl = TextEditingController(text: contact['number']);
    String contactType = contact['type'] ?? 'phone';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Edit Hubungan"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: numberCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Nombor Telefon',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: contactType,
                  items: const [
                    DropdownMenuItem(value: 'phone', child: Text('Panggilan Telefon')),
                    DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp')),
                  ],
                  onChanged: (val) {
                    setDialogState(() => contactType = val ?? 'phone');
                  },
                  decoration: const InputDecoration(labelText: 'Jenis Hubungan'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  List<dynamic> updatedContacts = List.from(widget.contacts);
                  updatedContacts[index] = {
                    'label': labelCtrl.text.trim(),
                    'number': numberCtrl.text.trim(),
                    'type': contactType,
                    'isActive': true,
                  };

                  await db.collection('shops').doc(widget.userId).update({
                    'contacts': updatedContacts,
                  });

                  widget.onUpdate();
                  Navigator.pop(ctx);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Hubungan berjaya dikemaskini!'),
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

  void _deleteContact(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Padam Hubungan"),
        content: const Text("Adakah anda pasti mahu memadam hubungan ini?"),
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
      List<dynamic> updatedContacts = List.from(widget.contacts);
      updatedContacts.removeAt(index);
      
      await db.collection('shops').doc(widget.userId).update({
        'contacts': updatedContacts,
      });
      
      widget.onUpdate();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🗑️ Hubungan dipadam'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.contact_phone, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text('Hubungi Kami di', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: _showAddContactDialog,
                  tooltip: 'Tambah Nombor',
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            if (widget.contacts.isEmpty)
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.phone_disabled, size: 40, color: Colors.grey),
                    const SizedBox(height: 8),
                    const Text('Tiada nombor hubungan ditambah'),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Nombor Pertama'),
                      onPressed: _showAddContactDialog,
                    ),
                  ],
                ),
              )
            else
              Column(
                children: widget.contacts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final contact = entry.value;
                  return ListTile(
                    leading: Icon(
                      contact['type'] == 'whatsapp' 
                          ? Icons.chat_bubble
                          : Icons.phone,
                      color: contact['type'] == 'whatsapp' ? Colors.green : Colors.blue,
                    ),
                    title: Text(contact['label'] ?? 'Nombor'),
                    subtitle: Text(contact['number']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _showEditContactDialog(index, contact),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
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
}