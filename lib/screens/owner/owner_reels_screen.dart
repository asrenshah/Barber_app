import 'package:flutter/material.dart';

class OwnerReelsScreen extends StatelessWidget {
  const OwnerReelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library, size: 80, color: Colors.deepPurple),
            SizedBox(height: 20),
            Text(
              'Content Management',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Reels management system coming soon...'),
          ],
        ),
      ),
    );
  }
}