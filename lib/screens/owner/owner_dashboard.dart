import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});
  
  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore db = FirebaseFirestore.instance;
  Map<String, dynamic>? shopData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  Future<void> _loadShopData() async {
    if (user == null) return;
    
    try {
      final doc = await db.collection('shops').doc(user!.uid).get();
      
      if (doc.exists) {
        if (mounted) {
          setState(() {
            shopData = doc.data();
            loading = false;
          });
        }
      } else {
        await db.collection('shops').doc(user!.uid).set({
          'name': '',
          'phone': '',
          'location': '',
          'coordinates': {
            'latitude': 0.0,
            'longitude': 0.0,
            'address': ''
          },
          'category': 'walk-in',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        final newDoc = await db.collection('shops').doc(user!.uid).get();
        if (mounted) {
          setState(() {
            shopData = newDoc.data();
            loading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading shop data: $e');
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  // ✅ FUNCTIONS INI AKAN KITA PINDAH KE PROFILE TAB NANTI
  // _editShopInfo() - PINDAH KE PROFILE
  // _setLocation() - PINDAH KE PROFILE  
  // _logout() - PINDAH KE PROFILE

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Business Dashboard"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        // ❌ BUANG BACK BUTTON - tak perlu dalam tab navigation
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ BUSINESS OVERVIEW CARD
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                                child: Icon(Icons.business, color: AppTheme.primaryColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Today's Overview",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Business Performance",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // ✅ QUICK STATS ROW
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem("Bookings", "8", Icons.calendar_today),
                              _buildStatItem("Revenue", "RM 420", Icons.attach_money),
                              _buildStatItem("Customers", "12", Icons.people),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // ✅ QUICK ACTIONS
                          const Text("Quick Actions", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Switch ke Bookings tab
                                    // Akan kita implement nanti
                                  },
                                  icon: const Icon(Icons.calendar_today, size: 18),
                                  label: const Text("View Bookings"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[50],
                                    foregroundColor: Colors.blue,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Switch ke Insights tab  
                                    // Akan kita implement nanti
                                  },
                                  icon: const Icon(Icons.analytics, size: 18),
                                  label: const Text("Analytics"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[50],
                                    foregroundColor: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // ✅ RECENT ACTIVITY SECTION
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Recent Activity",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          _buildActivityItem("Ali", "Haircut", "10:30 AM", true),
                          _buildActivityItem("Siti", "Coloring", "11:15 AM", false),
                          _buildActivityItem("Ahmad", "Beard Trim", "2:00 PM", true),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ✅ HELPER WIDGET - STAT ITEM
  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // ✅ HELPER WIDGET - ACTIVITY ITEM
  Widget _buildActivityItem(String name, String service, String time, bool completed) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: completed ? Colors.green[50] : Colors.orange[50],
          shape: BoxShape.circle,
        ),
        child: Icon(
          completed ? Icons.check : Icons.schedule,
          color: completed ? Colors.green : Colors.orange,
          size: 20,
        ),
      ),
      title: Text(name),
      subtitle: Text(service),
      trailing: Text(time, style: const TextStyle(color: Colors.grey)),
    );
  }
}