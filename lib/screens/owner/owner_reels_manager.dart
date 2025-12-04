// lib/screens/owner/owner_reels_manager.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'owner_reels_management.dart';

class OwnerReelsManager {
  final User? user;
  final Map<String, dynamic>? shopData;
  final Function(void Function()) setState;
  
  OwnerReelsManager({
    required this.user,
    required this.shopData,
    required this.setState,
  });

  final FirebaseFirestore db = FirebaseFirestore.instance;

  void navigateToReelsManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OwnerReelsManagementScreen()),
    );
  }

  Widget buildReelsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Your Reels", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Manage your video content"),
            IconButton(
              onPressed: () => navigateToReelsManagement(context),
              icon: const Icon(Icons.video_library),
              tooltip: 'Manage Reels',
            ),
          ],
        ),
        
        StreamBuilder<QuerySnapshot>(
          stream: db.collection('reels')
              .where('shopId', isEqualTo: user!.uid)
              .orderBy('createdAt', descending: true)
              .limit(3)
              .snapshots(),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return GestureDetector(
                onTap: () => navigateToReelsManagement(context),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.video_library, size: 50, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No reels yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap to create your first reel',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            final reels = snapshot.data!.docs;
            return Column(
              children: [
                ...reels.map((doc) {
                  final reel = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[300],
                      ),
                      child: const Icon(Icons.videocam, color: Colors.grey),
                    ),
                    title: Text(
                      reel['caption'] ?? 'No caption',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      reel['status'] == 'published' ? 'Published' : 'Draft',
                      style: TextStyle(
                        color: reel['status'] == 'published' ? Colors.green : Colors.orange,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => navigateToReelsManagement(context),
                  );
                }),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => navigateToReelsManagement(context),
                    child: const Text('View All Reels →'),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}