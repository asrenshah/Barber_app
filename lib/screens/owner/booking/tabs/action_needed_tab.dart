import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../models/booking_model.dart';
import '../../../../services/booking_service.dart';
import '../widgets/booking_card.dart';

class ActionNeededTab extends StatelessWidget {
  const ActionNeededTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }

    return StreamBuilder<List<Booking>>(
      stream: BookingService.getPendingBookings(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return const Center(
            child: Text('No bookings need action'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];

            return BookingCard(
              booking: booking,
            );
          },
        );
      },
    );
  }
}
