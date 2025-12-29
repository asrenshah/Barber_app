// lib/screens/owner/booking/tabs/history_tab.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../models/booking_model.dart';
import '../../../../services/booking_service.dart';
import '../widgets/booking_card.dart';

class HistoryTab extends StatelessWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Please login'));
    }

    return StreamBuilder<List<Booking>>(
      stream: BookingService.getHistoryBookings(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return const Center(
            child: Text(
              'No history available',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            
            return BookingCard(
              booking: booking,
              onUpdate: null, // History tak perlu onUpdate
            );
          },
        );
      },
    );
  }
}