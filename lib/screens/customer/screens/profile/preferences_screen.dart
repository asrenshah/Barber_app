import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _loading = true;
  bool _darkModeEnabled = false;
  
  // NOTIFICATION SECTION
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _bookingReminders = true;
  int _reminderTime = 30;
  
  // BOOKING PREFERENCE SECTION (NEW - yang anda minta)
  bool _autoConfirmBookings = false;
  bool _allowWalkIns = true;
  bool _savePaymentInfo = false;
  bool _allowRescheduling = true;
  bool _allowCancellations = true;
  int _cancellationWindow = 2; // hours
  
  // LANGUAGE (temporary hidden)
  // String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    if (_currentUser == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        // Appearance
        _darkModeEnabled = prefs.getBool('dark_mode') ?? false;
        
        // Notifications
        _emailNotifications = prefs.getBool('email_notifications') ?? true;
        _pushNotifications = prefs.getBool('push_notifications') ?? true;
        _bookingReminders = prefs.getBool('booking_reminders') ?? true;
        _reminderTime = prefs.getInt('reminder_time') ?? 30;
        
        // Booking Preferences
        _autoConfirmBookings = prefs.getBool('auto_confirm') ?? false;
        _allowWalkIns = prefs.getBool('allow_walkins') ?? true;
        _savePaymentInfo = prefs.getBool('save_payment') ?? false;
        _allowRescheduling = prefs.getBool('allow_rescheduling') ?? true;
        _allowCancellations = prefs.getBool('allow_cancellations') ?? true;
        _cancellationWindow = prefs.getInt('cancellation_window') ?? 2;
        
        // Language (temporary hidden)
        // _selectedLanguage = prefs.getString('language') ?? 'English';
      });

      // Load from Firestore if available
      final userDoc = await _firestore.collection('users').doc(_currentUser!.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        final prefsData = data['preferences'] ?? {};
        
        setState(() {
          // Notifications
          _emailNotifications = prefsData['emailNotifications'] ?? _emailNotifications;
          _pushNotifications = prefsData['pushNotifications'] ?? _pushNotifications;
          _bookingReminders = prefsData['bookingReminders'] ?? _bookingReminders;
          _reminderTime = prefsData['reminderTime'] ?? _reminderTime;
          
          // Booking Preferences
          _autoConfirmBookings = prefsData['autoConfirmBookings'] ?? _autoConfirmBookings;
          _allowWalkIns = prefsData['allowWalkIns'] ?? _allowWalkIns;
          _savePaymentInfo = prefsData['savePaymentInfo'] ?? _savePaymentInfo;
          _allowRescheduling = prefsData['allowRescheduling'] ?? _allowRescheduling;
          _allowCancellations = prefsData['allowCancellations'] ?? _allowCancellations;
          _cancellationWindow = prefsData['cancellationWindow'] ?? _cancellationWindow;
          
          // Language
          // _selectedLanguage = prefsData['language'] ?? _selectedLanguage;
        });
      }
          
      setState(() => _loading = false);
    } catch (e) {
      debugPrint('Error loading preferences: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _savePreference(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      }
      
      // Save to Firestore
      if (_currentUser != null) {
        await _firestore.collection('users').doc(_currentUser.uid).set({
          'preferences.$key': value,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error saving preference: $e');
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // APPEARANCE
  Future<void> _toggleDarkMode(bool value) async {
    setState(() => _darkModeEnabled = value);
    await _savePreference('dark_mode', value);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value ? 'Dark mode enabled' : 'Dark mode disabled'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // NOTIFICATIONS
  Future<void> _toggleEmailNotifications(bool value) async {
    setState(() => _emailNotifications = value);
    await _savePreference('email_notifications', value);
  }

  Future<void> _togglePushNotifications(bool value) async {
    setState(() => _pushNotifications = value);
    await _savePreference('push_notifications', value);
  }

  Future<void> _toggleBookingReminders(bool value) async {
    setState(() => _bookingReminders = value);
    await _savePreference('booking_reminders', value);
  }

  Future<void> _updateReminderTime(int? value) async {
    if (value != null) {
      setState(() => _reminderTime = value);
      await _savePreference('reminder_time', value);
    }
  }

  // BOOKING PREFERENCES
  Future<void> _toggleAutoConfirm(bool value) async {
    setState(() => _autoConfirmBookings = value);
    await _savePreference('auto_confirm', value);
  }

  Future<void> _toggleWalkIns(bool value) async {
    setState(() => _allowWalkIns = value);
    await _savePreference('allow_walkins', value);
  }

  Future<void> _toggleSavePayment(bool value) async {
    setState(() => _savePaymentInfo = value);
    await _savePreference('save_payment', value);
  }

  Future<void> _toggleRescheduling(bool value) async {
    setState(() => _allowRescheduling = value);
    await _savePreference('allow_rescheduling', value);
  }

  Future<void> _toggleCancellations(bool value) async {
    setState(() => _allowCancellations = value);
    await _savePreference('allow_cancellations', value);
  }

  Future<void> _updateCancellationWindow(int? value) async {
    if (value != null) {
      setState(() => _cancellationWindow = value);
      await _savePreference('cancellation_window', value);
    }
  }

  // LANGUAGE (temporary commented)
  // Future<void> _changeLanguage(String? value) async {
  //   if (value != null) {
  //     setState(() => _selectedLanguage = value);
  //     await _savePreference('language', value);
  //   }
  // }

  // WIDGET BUILDERS
  Widget _buildPreferenceItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    Color? iconColor,
    VoidCallback? onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (iconColor ?? Theme.of(context).primaryColor).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor ?? Theme.of(context).primaryColor, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  trailing,
                ],
              ),
            ),
          ),
        ),
        if (showDivider) const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderTimeSelector() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reminder Time Before Appointment',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _reminderTime,
            items: const [
              DropdownMenuItem(value: 15, child: Text('15 minutes before')),
              DropdownMenuItem(value: 30, child: Text('30 minutes before')),
              DropdownMenuItem(value: 60, child: Text('1 hour before')),
              DropdownMenuItem(value: 120, child: Text('2 hours before')),
              DropdownMenuItem(value: 1440, child: Text('1 day before')),
            ],
            onChanged: _updateReminderTime,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationWindowSelector() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cancellation Window',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _cancellationWindow,
            items: const [
              DropdownMenuItem(value: 1, child: Text('1 hour before')),
              DropdownMenuItem(value: 2, child: Text('2 hours before')),
              DropdownMenuItem(value: 4, child: Text('4 hours before')),
              DropdownMenuItem(value: 12, child: Text('12 hours before')),
              DropdownMenuItem(value: 24, child: Text('24 hours before')),
            ],
            onChanged: _updateCancellationWindow,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // LANGUAGE SELECTOR (temporary hidden)
  // Widget _buildLanguageSelector() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //     decoration: BoxDecoration(
  //       color: Colors.grey[50],
  //       borderRadius: BorderRadius.circular(12),
  //       border: Border.all(color: Colors.grey[200]!),
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Text(
  //           'App Language',
  //           style: TextStyle(
  //             fontWeight: FontWeight.w500,
  //             color: Colors.grey[700],
  //           ),
  //         ),
  //         const SizedBox(height: 8),
  //         DropdownButtonFormField<String>(
  //           value: _selectedLanguage,
  //           items: const [
  //             DropdownMenuItem(value: 'English', child: Text('English')),
  //             DropdownMenuItem(value: 'Malay', child: Text('Bahasa Malaysia')),
  //             DropdownMenuItem(value: 'Chinese', child: Text('中文')),
  //             DropdownMenuItem(value: 'Tamil', child: Text('தமிழ்')),
  //           ],
  //           onChanged: _changeLanguage,
  //           decoration: InputDecoration(
  //             filled: true,
  //             fillColor: Colors.white,
  //             border: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(8),
  //               borderSide: BorderSide(color: Colors.grey[300]!),
  //             ),
  //             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Preferences'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Theme.of(context).primaryColor),
              const SizedBox(height: 16),
              const Text('Loading your preferences...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPreferences,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECTION 1: APPEARANCE
            _buildSectionHeader('Appearance', 'Customize how the app looks'),
            
            _buildPreferenceItem(
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              subtitle: 'Switch between light and dark theme',
              iconColor: Colors.purple,
              trailing: Switch(
                value: _darkModeEnabled,
                onChanged: _toggleDarkMode,
                activeThumbColor: Theme.of(context).primaryColor,
              ),
            ),

            // LANGUAGE SELECTOR (temporary hidden)
            // _buildLanguageSelector(),
            
            // SECTION 2: NOTIFICATIONS
            _buildSectionHeader('Notifications', 'Control how we notify you'),
            
            _buildPreferenceItem(
              icon: Icons.email,
              title: 'Email Notifications',
              subtitle: 'Receive booking updates via email',
              iconColor: Colors.blue,
              trailing: Switch(
                value: _emailNotifications,
                onChanged: _toggleEmailNotifications,
                activeThumbColor: Theme.of(context).primaryColor,
              ),
            ),
            
            _buildPreferenceItem(
              icon: Icons.notifications,
              title: 'Push Notifications',
              subtitle: 'Receive app notifications on your device',
              iconColor: Colors.orange,
              trailing: Switch(
                value: _pushNotifications,
                onChanged: _togglePushNotifications,
                activeThumbColor: Theme.of(context).primaryColor,
              ),
            ),
            
            _buildPreferenceItem(
              icon: Icons.access_alarm,
              title: 'Booking Reminders',
              subtitle: 'Get reminded before your appointments',
              iconColor: Colors.green,
              trailing: Switch(
                value: _bookingReminders,
                onChanged: _toggleBookingReminders,
                activeThumbColor: Theme.of(context).primaryColor,
              ),
            ),
            
            if (_bookingReminders) _buildReminderTimeSelector(),
            
            // SECTION 3: BOOKING PREFERENCES (NEW)
            _buildSectionHeader('Booking Preferences', 'Customize your booking experience'),
            
            _buildPreferenceItem(
              icon: Icons.check_circle,
              title: 'Auto-Confirm Bookings',
              subtitle: 'Automatically confirm bookings without manual approval',
              iconColor: Colors.teal,
              trailing: Switch(
                value: _autoConfirmBookings,
                onChanged: _toggleAutoConfirm,
                activeThumbColor: Theme.of(context).primaryColor,
              ),
            ),
            
            _buildPreferenceItem(
              icon: Icons.directions_walk,
              title: 'Show Walk-in Availability',
              subtitle: 'Display shops that accept walk-ins',
              iconColor: Colors.red,
              trailing: Switch(
                value: _allowWalkIns,
                onChanged: _toggleWalkIns,
                activeThumbColor: Theme.of(context).primaryColor,
              ),
            ),
            
            _buildPreferenceItem(
              icon: Icons.credit_card,
              title: 'Save Payment Information',
              subtitle: 'Remember my payment methods for faster checkout',
              iconColor: Colors.amber,
              trailing: Switch(
                value: _savePaymentInfo,
                onChanged: _toggleSavePayment,
                activeThumbColor: Theme.of(context).primaryColor,
              ),
            ),
            
            _buildPreferenceItem(
              icon: Icons.schedule,
              title: 'Allow Rescheduling',
              subtitle: 'Enable option to reschedule bookings',
              iconColor: Colors.blue,
              trailing: Switch(
                value: _allowRescheduling,
                onChanged: _toggleRescheduling,
                activeThumbColor: Theme.of(context).primaryColor,
              ),
            ),
            
            _buildPreferenceItem(
              icon: Icons.cancel,
              title: 'Allow Cancellations',
              subtitle: 'Enable option to cancel bookings',
              iconColor: Colors.red,
              trailing: Switch(
                value: _allowCancellations,
                onChanged: _toggleCancellations,
                activeThumbColor: Theme.of(context).primaryColor,
              ),
            ),
            
            if (_allowCancellations) _buildCancellationWindowSelector(),
            
            // INFO CARD
            Container(
              margin: const EdgeInsets.only(top: 24, bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Preferences are saved automatically',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your settings sync across all devices in real-time',
                          style: TextStyle(
                            color: Colors.blue[700]!.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // RESET BUTTON
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Reset All Preferences'),
                      content: const Text('Are you sure you want to reset all preferences to default settings?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.clear();
                            _loadPreferences();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All preferences reset to default'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          child: const Text('Reset', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: const Text(
                  'Reset All Preferences',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}