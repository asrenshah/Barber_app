// lib/screens/owner/owner_reels_management.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'owner_reels_upload.dart';
import 'owner_reels_preview.dart';

class OwnerReelsManagementScreen extends StatefulWidget {
  const OwnerReelsManagementScreen({super.key});

  @override
  State<OwnerReelsManagementScreen> createState() => _OwnerReelsManagementScreenState();
}

class _OwnerReelsManagementScreenState extends State<OwnerReelsManagementScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final db = FirebaseFirestore.instance;

  void _navigateToUpload() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OwnerReelsUploadScreen()),
    );
  }

  void _previewReel(Map<String, dynamic> reel) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OwnerReelsPreviewScreen(reel: reel)),
    );
  }

  Future<void> _publishReel(String reelId) async {
    await db.collection('reels').doc(reelId).update({
      'status': 'published',
      'publishedAt': FieldValue.serverTimestamp(),
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Reel published! Now visible in feed.')),
    );
  }

  Future<void> _deleteReel(String reelId) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Reel"),
        content: const Text("Are you sure you want to delete this reel?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await db.collection('reels').doc(reelId).delete();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reel deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildReelStatus(String status) {
    switch (status) {
      case 'draft':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange),
          ),
          child: Text(
            'DRAFT',
            style: TextStyle(
              fontSize: 10,
              color: Colors.orange[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      case 'published':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green),
          ),
          child: Text(
            'PUBLISHED',
            style: TextStyle(
              fontSize: 10,
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Reels"),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToUpload,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.video_library, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection('reels')
            .where('shopId', isEqualTo: user!.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No reels yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Upload your first reel to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _navigateToUpload,
                    icon: const Icon(Icons.video_library),
                    label: const Text('Upload First Reel'),
                  ),
                ],
              ),
            );
          }
          
          final reels = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reels.length,
            itemBuilder: (context, index) {
              final reel = reels[index].data() as Map<String, dynamic>;
              final reelId = reels[index].id;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: GestureDetector(
                    onTap: () => _previewReel(reel),
                    child: Stack(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[300],
                          ),
                          child: reel['thumbnailUrl']?.isNotEmpty == true
                              ? CachedNetworkImage(
                                  imageUrl: reel['thumbnailUrl'],
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.videocam, color: Colors.grey),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '15s', // Placeholder - boleh calculate actual duration
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  title: Text(
                    reel['caption'] ?? 'No caption',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      _buildReelStatus(reel['status'] ?? 'draft'),
                      const SizedBox(height: 4),
                      Text(
                        '${reel['likes'] ?? 0} likes • ${reel['views'] ?? 0} views',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'preview') {
                        _previewReel(reel);
                      } else if (value == 'publish' && reel['status'] != 'published') {
                        _publishReel(reelId);
                      } else if (value == 'delete') {
                        _deleteReel(reelId);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'preview',
                        child: Row(
                          children: [
                            Icon(Icons.play_arrow, size: 20),
                            SizedBox(width: 8),
                            Text('Preview'),
                          ],
                        ),
                      ),
                      if (reel['status'] != 'published')
                        const PopupMenuItem(
                          value: 'publish',
                          child: Row(
                            children: [
                              Icon(Icons.publish, size: 20),
                              SizedBox(width: 8),
                              Text('Publish'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}