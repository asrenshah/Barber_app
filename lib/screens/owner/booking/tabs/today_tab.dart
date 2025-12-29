import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../models/booking_model.dart';
import '../../../../services/booking_service.dart';
import '../widgets/booking_card.dart';

class TodayTab extends StatelessWidget {
  const TodayTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return StreamBuilder<List<Booking>>(
      stream: BookingService.getTodayBookings(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No bookings today'));
        }

        final bookings = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            return BookingCard(
              booking: bookings[index],
              onUpdate: () {}, // Stream auto refresh
            );
          },
        );
      },
    );
  }
}
