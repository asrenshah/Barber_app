import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../services/dashboard_service.dart';
import '../../models/barber_model.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});
  
  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  final User? user = FirebaseAuth.instance.currentUser;
  late DashboardService dashboardService;
  
  // Stats Data - SEMUA 0 (REAL)
  Map<String, dynamic> stats = {
    'todayAppointments': 0,   // ← REAL (0 jika tak ada)
    'todayRevenue': 0.0,      // ← REAL (0 jika tak ada)
    'totalCustomers': 0,      // ← REAL (0 jika tak ada)
    'averageRating': 0.0,     // ← REAL (0 jika tak ada)
    'activeBarbers': 0,       // ← REAL (0 jika tak ada)
    'monthlyGrowth': 0.0,     // ← REAL (0 jika tak ada)
  };
  
  List<Map<String, dynamic>> todayAppointments = []; // ← REAL (kosong jika tak ada)
  List<Barber> activeBarbers = []; // ← REAL (kosong jika tak ada)
  bool loading = true;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      dashboardService = DashboardService(userId: user!.uid);
      _loadDashboardData();
    } else {
      loading = false;
    }
  }

  Future<void> _loadDashboardData() async {
    if (user == null) return;
    
    setState(() => loading = true);
    
    try {
      // LOAD REAL DATA DARI FIRESTORE
      final results = await Future.wait([
        dashboardService.getTodayAppointmentsCount(),
        dashboardService.getTodayRevenue(),
        dashboardService.getTotalCustomers(),
        dashboardService.getAverageRating(),
        dashboardService.getActiveBarbers(),
        dashboardService.getMonthlyStats(),
        dashboardService.getTodayAppointments(),
      ]);
      
      // SET REAL DATA KE STATE
      setState(() {
        stats['todayAppointments'] = results[0] as int;
        stats['todayRevenue'] = results[1] as double;
        stats['totalCustomers'] = results[2] as int;
        stats['averageRating'] = results[3] as double;
        activeBarbers = results[4] as List<Barber>;
        stats['activeBarbers'] = activeBarbers.length;
        
        final monthlyStats = results[5] as Map<String, dynamic>;
        stats['monthlyGrowth'] = monthlyStats['growth'];
        
        todayAppointments = results[6] as List<Map<String, dynamic>>;
        loading = false;
      });
      
    } catch (e) {
      print('❌ Error loading dashboard data: $e');
      
      // ⬇️⬇️⬇️ TIDAK ADA DUMMY DATA! GUNA 0 SAHAJA! ⬇️⬇️⬇️
      setState(() {
        // SEMUA KOSONG/0 - REAL STATE
        stats = {
          'todayAppointments': 0,
          'todayRevenue': 0.0,
          'totalCustomers': 0,
          'averageRating': 0.0,
          'activeBarbers': 0,
          'monthlyGrowth': 0.0,
        };
        
        todayAppointments = [];
        activeBarbers = [];
        loading = false;
      });
      
      // Tunjuk error message (optional)
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: ${e.toString().split(':').last}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ✅ STATS CARDS - REAL DATA
  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.3,
      padding: EdgeInsets.zero,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        _buildStatCard(
          'Today\'s Appointments',
          stats['todayAppointments'].toString(),
          Icons.calendar_today,
          Colors.blue,
        ),
        _buildStatCard(
          'Today\'s Revenue',
          'RM ${stats['todayRevenue'].toStringAsFixed(0)}',
          Icons.attach_money,
          Colors.green,
        ),
        _buildStatCard(
          'Total Customers',
          stats['totalCustomers'].toString(),
          Icons.people,
          Colors.purple,
        ),
        _buildStatCard(
          'Avg Rating',
          stats['averageRating'] > 0 ? stats['averageRating'].toStringAsFixed(1) : 'N/A',
          Icons.star,
          Colors.amber,
        ),
        _buildStatCard(
          'Active Barbers',
          stats['activeBarbers'].toString(),
          Icons.content_cut,
          Colors.deepOrange,
        ),
        _buildStatCard(
          'Monthly Growth',
          stats['monthlyGrowth'] > 0 ? '${stats['monthlyGrowth'].toStringAsFixed(1)}%' : '0%',
          stats['monthlyGrowth'] > 0 ? Icons.trending_up : Icons.trending_flat,
          stats['monthlyGrowth'] > 0 ? Colors.green : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ TODAY'S APPOINTMENTS LIST - REAL DATA
  Widget _buildAppointmentsList() {
    if (todayAppointments.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.calendar_today, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text('No appointments today', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  "Today's Appointments",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to bookings screen
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...todayAppointments.map((appointment) {
              return _buildAppointmentItem(appointment);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentItem(Map<String, dynamic> appointment) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.pending;
    
    switch (appointment['status']) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment['customerName'],
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  appointment['service'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                appointment['time'],
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                'RM ${appointment['price']}',
                style: const TextStyle(fontSize: 12, color: Colors.green),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ ACTIVE BARBERS SECTION - REAL DATA
  Widget _buildBarbersSection() {
    if (activeBarbers.isEmpty) {
      return const SizedBox();
    }
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.content_cut, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  "Active Barbers",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: activeBarbers.map((barber) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(barber.name[0]),
                  ),
                  label: Text(barber.name),
                  backgroundColor: barber.isActive 
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: barber.isActive ? Colors.green : Colors.grey,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NAVIGATION GUIDE
  Widget _buildNavigationGuide() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.navigation, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  "Navigate To",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                _buildNavItem(
                  Icons.calendar_today,
                  'Bookings Tab',
                  'Manage appointments & schedule',
                  Colors.blue,
                ),
                _buildNavItem(
                  Icons.video_library,
                  'Content Tab',
                  'Post reels & manage marketing',
                  Colors.purple,
                ),
                _buildNavItem(
                  Icons.person,
                  'Profile Tab',
                  'Shop settings & barber management',
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String title, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Business Dashboard"),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🎯 WELCOME HEADER
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                              child: const Icon(Icons.business, color: AppTheme.primaryColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Welcome Back!",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('EEEE, MMMM d').format(DateTime.now()),
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
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // 📊 STATS GRID (REAL DATA)
                    _buildStatsGrid(),
                    
                    const SizedBox(height: 20),
                    
                    // 🧭 NAVIGATION GUIDE
                    _buildNavigationGuide(),
                    
                    const SizedBox(height: 20),
                    
                    // 👥 ACTIVE BARBERS (REAL DATA)
                    _buildBarbersSection(),
                    
                    const SizedBox(height: 20),
                    
                    // 📅 TODAY'S APPOINTMENTS (REAL DATA)
                    _buildAppointmentsList(),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}