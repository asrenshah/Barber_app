// lib/screens/owner/reels/owner_reels_management.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'owner_reels_upload.dart';
import 'owner_reels_preview.dart';
import '../../../models/reel_model.dart';

class OwnerReelsManagement extends StatefulWidget {
  const OwnerReelsManagement({super.key});

  @override
  State<OwnerReelsManagement> createState() => _OwnerReelsManagementState();
}

class _OwnerReelsManagementState extends State<OwnerReelsManagement>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  List<Reel> _reels = [];

  @override
  void initState() {
    super.initState();
    _loadReels();
  }

  Future<void> _loadReels() async {
    if (_user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('reels')
          .where('shopId', isEqualTo: _user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        _reels = snapshot.docs
            .map((doc) => Reel.fromFirestore(doc))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Load reels error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _navigateToUpload({Reel? reel}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OwnerReelsUpload(
          reelData: reel?.toFirestore(),
        ),
      ),
    ).then((_) => _loadReels());
  }

  void _previewReel(Reel reel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OwnerReelsPreviewScreen(reel: reel.toFirestore()),
      ),
    );
  }

  // 🎯 NEW: PUBLISH CONFIRMATION DIALOG
  Future<void> _showPublishConfirmation(Reel reel) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.publish, color: Colors.green),
            SizedBox(width: 8),
            Text('Terbitkan Reel'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Adakah anda pasti ingin menerbitkan reel ini?'),
            const SizedBox(height: 12),
            
            // Video Info
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Caption:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reel.caption.isNotEmpty ? '"${reel.caption}"' : '(Tiada caption)',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.video_library, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${reel.formattedViews} tontonan',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.thumb_up, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${reel.likes} suka',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              '📍 Video akan muncul di:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 8),
            const Text('• Reels Feed pelanggan'),
            const Text('• Halaman Shop anda'),
            const Text('• Trending section (jika trending)'),
            
            const SizedBox(height: 12),
            const Text(
              '⚠️ Nota:',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
            const Text(
              '• Video akan dilihat oleh semua pelanggan',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const Text(
              '• Anda boleh tarik balik ke draft bila-bila masa',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _publishReel(reel.id);  // Execute publish
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Terbitkan Sekarang'),
          ),
        ],
      ),
    );
  }

  Future<void> _publishReel(String reelId) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Menerbitkan reel...'),
            ],
          ),
        ),
      );

      // 🎯 UPDATE FIRESTORE: PUBLISH THE REEL
      await _firestore.collection('reels').doc(reelId).update({
        'status': 'published',
        'isPublic': true,  // 🎯 NEW FIELD: Make it public
        'publishedAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Reel berjaya diterbitkan!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Refresh the list
      _loadReels();

    } catch (e) {
      // Close loading dialog if error
      if (mounted) Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Gagal menerbitkan: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🎯 NEW: UNPUBLISH FUNCTION
  Future<void> _unpublishReel(String reelId) async {
    try {
      await _firestore.collection('reels').doc(reelId).update({
        'status': 'draft',
        'isPublic': false,  // 🎯 Make it private again
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      _loadReels();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reel dikembalikan ke draft'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteReel(String reelId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Padam Reel'),
        content: const Text('Anda pasti mahu padam reel ini? Tindakan ini tidak boleh dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Padam', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Memadam reel...'),
              ],
            ),
          ),
        );

        await _firestore.collection('reels').doc(reelId).delete();
        
        if (mounted) Navigator.pop(context); // Close loading
        
        _loadReels();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reel berjaya dipadam'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (mounted) Navigator.pop(context); // Close loading if error
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal memadam: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatusBadge(String status) {
    late Color color;
    late IconData icon;
    late String text;

    switch (status) {
      case 'published':
        color = Colors.green;
        icon = Icons.check_circle;
        text = 'TERBIT';
        break;
      case 'scheduled':
        color = Colors.blue;
        icon = Icons.schedule;
        text = 'TERJADUAL';
        break;
      default:
        color = Colors.orange;
        icon = Icons.drafts;
        text = 'DRAFT';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReelItem(Reel reel) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            imageUrl: reel.thumbnailUrl ?? '',
            placeholder: (_, __) =>
                Container(color: Colors.grey[300]),
            errorWidget: (_, __, ___) =>
                Container(
                  color: Colors.grey[200],
                  child: Icon(Icons.videocam, color: Colors.grey[600]),
                ),
          ),
        ),
        title: Text(
          reel.caption.length > 50
              ? '${reel.caption.substring(0, 50)}...'
              : reel.caption,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            _buildStatusBadge(reel.status),
            const SizedBox(height: 4),
            Text(
              '${reel.formattedViews} tontonan • ${reel.likes} suka',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            if (reel.publishedAt != null)
              Text(
                'Diterbitkan: ${_formatDate(reel.publishedAt!)}',
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'preview') _previewReel(reel);
            if (value == 'edit') _navigateToUpload(reel: reel);
            if (value == 'publish' && !reel.isPublished) {
              _showPublishConfirmation(reel);  // 🎯 NEW: Show confirmation dialog
            }
            if (value == 'unpublish' && reel.isPublished) {
              _unpublishReel(reel.id);  // 🎯 NEW: Unpublish option
            }
            if (value == 'delete') _deleteReel(reel.id);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: 'preview',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 18),
                  SizedBox(width: 8),
                  Text('Pratonton'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            if (!reel.isPublished)
              const PopupMenuItem(
                value: 'publish',
                child: Row(
                  children: [
                    Icon(Icons.publish, size: 18, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Terbitkan', style: TextStyle(color: Colors.green)),
                  ],
                ),
              ),
            if (reel.isPublished)
              const PopupMenuItem(
                value: 'unpublish',
                child: Row(
                  children: [
                    Icon(Icons.undo, size: 18, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Kembali ke Draft', style: TextStyle(color: Colors.orange)),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Padam', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _previewReel(reel),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Tiada Reels Lagi',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Gunakan butang + untuk upload video pertama',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_user == null) {
      return const Center(child: Text('Sila log masuk'));
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reels.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadReels,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _reels.length,
        itemBuilder: (_, i) => _buildReelItem(_reels[i]),
      ),
    );
  }
}