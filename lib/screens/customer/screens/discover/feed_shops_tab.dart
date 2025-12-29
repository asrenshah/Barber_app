// lib/screens/customer/feed_shops_tab.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FeedShopsTab extends StatelessWidget {
  const FeedShopsTab({super.key});

  void _viewShopProfile(String shopId) {
    // TODO: Implement shop profile navigation
    print('Viewing shop profile: $shopId');
  }

  void _toggleFavorite(String shopId, String shopName, BuildContext context) {
    // TODO: Implement favorite functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $shopName to favorites! ❤️'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildShopCard(BuildContext context, Map<String, dynamic> shop, String shopId) {
    final shopName = shop['name'] ?? 'Beauty Shop';
    final category = shop['category']?.toString().toUpperCase() ?? 'BEAUTY';
    final location = shop['location'] ?? 'Location not set';
    final rating = shop['rating'] ?? 4.5;
    final isOpen = shop['isOpen'] ?? true;
    final phone = shop['phone'] ?? '';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _viewShopProfile(shopId),
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Image
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      color: Colors.grey[200],
                    ),
                    child: shop['profileImage'] != null && shop['profileImage'].isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: shop['profileImage'],
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => const Icon(Icons.store, size: 40),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.store, size: 40, color: Colors.grey),
                          ),
                  ),
                ),
                
                // Shop Info
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Shop Name
                        Text(
                          shopName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        // Category & Location
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    location,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // ✅ TAMBAHAN: Rating & Status Row
                        Row(
                          children: [
                            // Rating
                            Row(
                              children: [
                                const Icon(Icons.star, size: 12, color: Colors.amber),
                                const SizedBox(width: 2),
                                Text(
                                  rating.toString(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // Open Status
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isOpen ? Colors.green[50] : Colors.red[50],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isOpen ? Colors.green[100]! : Colors.red[100]!,
                                ),
                              ),
                              child: Text(
                                isOpen ? 'OPEN' : 'CLOSED',
                                style: TextStyle(
                                  color: isOpen ? Colors.green[800] : Colors.red[800],
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ✅ TAMBAHAN: Favorite Button
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.favorite_border, size: 16),
                  onPressed: () => _toggleFavorite(shopId, shopName, context),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),

            // ✅ TAMBAHAN: Phone Call Button (jika ada phone)
            if (phone.isNotEmpty)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.phone, size: 14),
                    onPressed: () {
                      // TODO: Implement phone call
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Calling $shopName...'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('shops').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text(
                  'No shops yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Shop owners will register their businesses soon!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        }
        
        final shops = snapshot.data!.docs;
        
        return Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: shops.length,
            itemBuilder: (context, index) {
              final shop = shops[index].data() as Map<String, dynamic>;
              final shopId = shops[index].id;
              return _buildShopCard(context, shop, shopId);
            },
          ),
        );
      },
    );
  }
}