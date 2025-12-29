import 'package:flutter/material.dart';

class OwnerFeedScreen extends StatelessWidget {
  const OwnerFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics,
            size: 80,
            color: Colors.deepPurple,
          ),
          SizedBox(height: 20),
          Text(
            'Business Intelligence Dashboard',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Market insights & analytics coming soon...',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
