import 'package:flutter/material.dart';
import 'owner_reels_management.dart';
import 'owner_reels_upload.dart';

class OwnerReelsScreen extends StatelessWidget {
  const OwnerReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Content Management"),
        backgroundColor: Colors.deepPurple,  // ← GANTI DENGAN INI
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Maklumat Content Management'),
                  content: const Text(
                    '1. Upload video sebagai DRAFT terlebih dahulu\n'
                    '2. Terbitkan video untuk paparan kepada pelanggan\n'
                    '3. Video diterbitkan akan muncul di Reels Feed pelanggan\n'
                    '4. Anda boleh tarik balik video ke draft bila-bila masa',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: const OwnerReelsManagement(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OwnerReelsUpload(),
            ),
          );
        },
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),  // ← GANTI DENGAN INI
      ),
    );
  }
}