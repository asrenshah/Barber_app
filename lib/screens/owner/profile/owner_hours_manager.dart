// lib/screens/owner/profile/owner_hours_manager.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerHoursManager extends StatefulWidget {
  final Map<String, dynamic> hours;
  final String userId;
  final Function onUpdate;
  
  const OwnerHoursManager({
    super.key,
    required this.hours,
    required this.userId,
    required this.onUpdate,
  });
  
  @override
  State<OwnerHoursManager> createState() => _OwnerHoursManagerState();
}

class _OwnerHoursManagerState extends State<OwnerHoursManager> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  
  final List<Map<String, String>> _days = [
    {'en': 'Monday', 'ms': 'Isnin'},
    {'en': 'Tuesday', 'ms': 'Selasa'},
    {'en': 'Wednesday', 'ms': 'Rabu'},
    {'en': 'Thursday', 'ms': 'Khamis'},
    {'en': 'Friday', 'ms': 'Jumaat'},
    {'en': 'Saturday', 'ms': 'Sabtu'},
    {'en': 'Sunday', 'ms': 'Ahad'},
  ];

  TimeOfDay _parseTime(String? timeStr) {
    if (timeStr == null) return const TimeOfDay(hour: 9, minute: 0);
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  void _editOperatingHours() async {
    Map<String, dynamic> currentHours = Map.from(widget.hours);
    
    // Initialize empty hours for all days
    for (var day in _days) {
      if (!currentHours.containsKey(day['en']!.toString())) {
        currentHours[day['en']!.toString()] = {'open': null, 'close': null};
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.access_time, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text("Edit Waktu Operasi"),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                itemCount: _days.length,
                itemBuilder: (context, index) {
                  final day = _days[index];
                  final dayData = currentHours[day['en']!.toString()] ?? {'open': null, 'close': null};
                  
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      title: Text(day['ms']!.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: () async {
                                    final TimeOfDay? picked = await showTimePicker(
                                      context: context,
                                      initialTime: _parseTime(dayData['open']),
                                    );
                                    if (picked != null) {
                                      setDialogState(() {
                                        currentHours[day['en']!.toString()]!['open'] = 
                                            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                                      });
                                    }
                                  },
                                  child: Text(
                                    dayData['open'] ?? 'Pilih waktu buka',
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                ),
                              ),
                              const Text(" - "),
                              Expanded(
                                child: TextButton(
                                  onPressed: () async {
                                    final TimeOfDay? picked = await showTimePicker(
                                      context: context,
                                      initialTime: _parseTime(dayData['close']),
                                    );
                                    if (picked != null) {
                                      setDialogState(() {
                                        currentHours[day['en']!.toString()]!['close'] = 
                                            "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                                      });
                                    }
                                  },
                                  child: Text(
                                    dayData['close'] ?? 'Pilih waktu tutup',
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        onPressed: () {
                          setDialogState(() {
                            currentHours[day['en']!.toString()] = {'open': null, 'close': null};
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Batal"),
              ),
              ElevatedButton(
                onPressed: () async {
                  await db.collection('shops').doc(widget.userId).update({
                    'operatingHours': currentHours,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  widget.onUpdate();
                  Navigator.pop(ctx);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Waktu operasi berjaya dikemaskini!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text("Simpan Semua"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text('Waktu Operasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: _editOperatingHours,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Column(
              children: _days.map((day) {
                final dayHours = widget.hours[day['en']!.toString()];
                final isOpen = dayHours != null && dayHours['open'] != null;
                
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: SizedBox(width: 80, child: Text(day['ms']!.toString())),
                  title: isOpen 
                      ? Text('${dayHours['open']} - ${dayHours['close']}')
                      : const Text('Tutup', style: TextStyle(color: Colors.grey)),
                  trailing: Icon(isOpen ? Icons.check_circle : Icons.cancel, 
                      color: isOpen ? Colors.green : Colors.grey, size: 18),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}