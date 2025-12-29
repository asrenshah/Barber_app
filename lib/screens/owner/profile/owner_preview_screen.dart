// lib/screens/owner/profile/owner_preview_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class OwnerPreviewScreen extends StatefulWidget {
  final Map<String, dynamic> shopData;
  final VoidCallback onBack;
  
  const OwnerPreviewScreen({
    super.key,
    required this.shopData,
    required this.onBack,
  });
  
  @override
  State<OwnerPreviewScreen> createState() => _OwnerPreviewScreenState();
}

class _OwnerPreviewScreenState extends State<OwnerPreviewScreen> with SingleTickerProviderStateMixin {
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
  
  void _launchContact(String number, String type) async {
    final url = type == 'whatsapp' 
        ? 'https://wa.me/6$number'
        : 'tel:$number';
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e) {
      print('Cannot launch: $e');
    }
  }
  
  Widget _buildFacebookStyleHeader() {
    final bannerUrl = widget.shopData['bannerImage'];
    final profileUrl = widget.shopData['profileImage'];
    
    return Stack(
      children: [
        // BANNER BESAR
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            image: bannerUrl != null
                ? DecorationImage(
                    image: CachedNetworkImageProvider(bannerUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
        ),
        
        // PROFILE CIRCLE (DI ATAS BANNER)
        Positioned(
          bottom: 0,
          left: 16,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 8,
                  color: Colors.black26,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey[200],
              backgroundImage: profileUrl != null
                  ? CachedNetworkImageProvider(profileUrl)
                  : null,
              child: profileUrl == null
                  ? const Icon(Icons.store, size: 40, color: Colors.grey)
                  : null,
            ),
          ),
        ),
        
        // STATS CHIPS (KANAN ATAS)
        Positioned(
          top: 16,
          right: 16,
          child: Wrap(
            spacing: 8,
            children: [
              Chip(
                label: Text('${widget.shopData['stats']?['followerCount'] ?? 0} Followers'),
                backgroundColor: Colors.white.withOpacity(0.9),
              ),
              Chip(
                label: Text('⭐ ${widget.shopData['stats']?['averageRating']?.toStringAsFixed(1) ?? '0.0'}'),
                backgroundColor: Colors.amber.withOpacity(0.9),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          // PREVIEW INFO
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.visibility, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  'PREVIEW MODE - Butang tidak aktif',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // DISABLED BUTTONS
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add, color: Colors.grey[500]),
                        const SizedBox(width: 8),
                        Text(
                          'Follow',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.message, color: Colors.grey[500]),
                        const SizedBox(width: 8),
                        Text(
                          'Message',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey[500]),
                        const SizedBox(width: 8),
                        Text(
                          'Book',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildShopInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.shopData['name'] ?? 'Nama Kedai',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (widget.shopData['location']?.isNotEmpty == true)
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.shopData['location']!,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          if (widget.shopData['category']?.isNotEmpty == true)
            Chip(
              label: Text(widget.shopData['category']!),
              backgroundColor: Colors.deepPurple[50],
            ),
        ],
      ),
    );
  }
  
  Widget _buildTabContent() {
    switch (_tabController.index) {
      case 0: // POSTS
        return _buildPostsTab();
      case 1: // SERVICES
        return _buildServicesTab();
      case 2: // ABOUT
        return _buildAboutTab();
      default:
        return Container();
    }
  }
  
  Widget _buildPostsTab() {
    // Placeholder untuk posts/reels
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Posts & Reels',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Content will appear here',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
  
  Widget _buildServicesTab() {
    final services = widget.shopData['services'] ?? [];
    
    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No Services Yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple[50],
              child: Text(
                "RM${service['price']?.toStringAsFixed(0) ?? '0'}",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            title: Text(service['name'] ?? 'Service'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  "${service['duration'] ?? 30} minit",
                  style: const TextStyle(fontSize: 12),
                ),
                if (service['description']?.isNotEmpty == true)
                  Text(
                    service['description']!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'BOOK',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAboutTab() {
    final hours = widget.shopData['operatingHours'] ?? {};
    final contacts = widget.shopData['contacts'] ?? [];
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Operating Hours
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '⏰ Waktu Operasi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ..._buildOperatingHoursList(hours),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Contact Information
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📞 Hubungi Kami',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ..._buildContactList(contacts),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Business Info
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🏢 Maklumat Perniagaan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.category, color: Colors.grey),
                  title: const Text('Kategori'),
                  subtitle: Text(widget.shopData['category'] ?? 'Walk-in'),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.grey),
                  title: const Text('Dalam Perniagaan'),
                  subtitle: Text('Since ${_formatDate(widget.shopData['createdAt'])}'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  List<Widget> _buildOperatingHoursList(Map<String, dynamic> hours) {
    final days = [
      {'en': 'Monday', 'ms': 'Isnin'},
      {'en': 'Tuesday', 'ms': 'Selasa'},
      {'en': 'Wednesday', 'ms': 'Rabu'},
      {'en': 'Thursday', 'ms': 'Khamis'},
      {'en': 'Friday', 'ms': 'Jumaat'},
      {'en': 'Saturday', 'ms': 'Sabtu'},
      {'en': 'Sunday', 'ms': 'Ahad'},
    ];
    
    return days.map((day) {
      final dayHours = hours[day['en']];
      final isOpen = dayHours != null && dayHours['open'] != null;
      
      return ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: SizedBox(width: 80, child: Text(day['ms']!)),
        title: isOpen
            ? Text('${dayHours['open']} - ${dayHours['close']}')
            : const Text('Tutup', style: TextStyle(color: Colors.grey)),
        trailing: Icon(
          isOpen ? Icons.check_circle : Icons.cancel,
          color: isOpen ? Colors.green : Colors.grey,
          size: 18,
        ),
      );
    }).toList();
  }
  
  List<Widget> _buildContactList(List<dynamic> contacts) {
    if (contacts.isEmpty) {
      return [
        const ListTile(
          leading: Icon(Icons.phone_disabled, color: Colors.grey),
          title: Text('Tiada nombor hubungan'),
        ),
      ];
    }
    
    return contacts.map((contact) {
      return ListTile(
        leading: Icon(
          contact['type'] == 'whatsapp' ? Icons.chat : Icons.phone,
          color: contact['type'] == 'whatsapp' ? Colors.green : Colors.blue,
        ),
        title: Text(contact['label'] ?? 'Nombor'),
        subtitle: Text(contact['number']),
        trailing: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.message,
            size: 18,
            color: Colors.grey[500],
          ),
        ),
      );
    }).toList();
  }
  
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '2024';
    try {
      final date = timestamp.toDate();
      return '${date.year}';
    } catch (e) {
      return '2024';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Preview: ${widget.shopData['name'] ?? 'Kedai'}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
      ),
      body: DefaultTabController(
        length: 3,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFacebookStyleHeader(),
                    _buildShopInfo(),
                    _buildActionButtons(),
                  ],
                ),
              ),
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'POSTS'),
                      Tab(text: 'SERVICES'),
                      Tab(text: 'ABOUT'),
                    ],
                    labelColor: Colors.deepPurple,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Colors.deepPurple,
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPostsTab(),
              _buildServicesTab(),
              _buildAboutTab(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onBack,
        icon: const Icon(Icons.edit),
        label: const Text('Kembali ke Edit'),
        backgroundColor: Colors.deepPurple,
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}