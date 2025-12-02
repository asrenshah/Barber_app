// lib/screens/customer/feed_screen.dart
import 'package:flutter/material.dart';
import 'widgets/custom_tab_bar.dart';
import 'feed_reels_tab.dart';
import 'feed_shops_tab.dart';
import 'feed_trending_tab.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Discover Beauty',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Custom Tab Bar
          CustomTabBar(tabController: _tabController),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                FeedReelsTab(),     // 🎬 Tab 1 - TikTok-style Reels
                FeedShopsTab(),     // 🏪 Tab 2 - Shop Discovery
                FeedTrendingTab(),  // ⭐ Tab 3 - Trending Content
              ],
            ),
          ),
        ],
      ),
    );
  }
}