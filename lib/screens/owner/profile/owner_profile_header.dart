// lib/screens/owner/profile/owner_profile_header.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OwnerProfileHeader extends StatelessWidget {
  final Map<String, dynamic>? shopData;
  final Function(bool) onImagePick;
  
  const OwnerProfileHeader({
    super.key,
    required this.shopData,
    required this.onImagePick,
  });
  
  @override
  Widget build(BuildContext context) {
    final bannerUrl = shopData?['bannerImage'];
    final profileUrl = shopData?['profileImage'];
    
    return SizedBox(
      height: 220,
      child: Stack(
        children: [
          // BANNER
          GestureDetector(
            onTap: () => onImagePick(true),
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                image: bannerUrl != null ? DecorationImage(
                  image: CachedNetworkImageProvider(bannerUrl),
                  fit: BoxFit.cover,
                ) : null,
              ),
              child: bannerUrl == null ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[600]),
                    const SizedBox(height: 8),
                    Text('Klik untuk tambah banner', style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
              ) : null,
            ),
          ),
          
          // GAMBAR PROFIL
          Positioned(
            bottom: 0,
            left: 16,
            child: GestureDetector(
              onTap: () => onImagePick(false),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black26)],
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: profileUrl != null 
                      ? CachedNetworkImageProvider(profileUrl)
                      : null,
                  child: profileUrl == null 
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
              ),
            ),
          ),
          
          // STATISTIK RINGKAS
          Positioned(
            bottom: 10,
            right: 16,
            child: Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text('${shopData?['stats']?['totalBookings'] ?? 0} Tempahan'),
                  backgroundColor: Colors.deepPurple.withOpacity(0.1),
                ),
                Chip(
                  label: Text('⭐ ${shopData?['stats']?['averageRating']?.toStringAsFixed(1) ?? '0.0'}'),
                  backgroundColor: Colors.amber.withOpacity(0.1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}