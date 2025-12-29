// lib/screens/owner/booking/booking_screen.dart
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'tabs/today_tab.dart';
import 'tabs/action_needed_tab.dart';
import 'tabs/upcoming_tab.dart';
import 'tabs/history_tab.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Tab> myTabs = const [
    Tab(text: 'Today'),
    Tab(text: 'Action Needed'),
    Tab(text: 'Upcoming'),
    Tab(text: 'History'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: myTabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        backgroundColor: AppTheme.primaryColor, // Bar ungu premium
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: myTabs,
          indicatorColor: Colors.white, // Bar highlight ungu
          indicatorWeight: 4,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          TodayTab(),
          ActionNeededTab(),
          UpcomingTab(),
          HistoryTab(),
        ],
      ),
    );
  }
}
