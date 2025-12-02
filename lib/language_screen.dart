import 'package:flutter/material.dart';

class LanguageScreen extends StatelessWidget {
  final Function(String) onLanguageSelected;

  const LanguageScreen({super.key, required this.onLanguageSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Choose Language")),
      body: ListView(
        children: [
          ListTile(
            title: const Text("English"),
            onTap: () => onLanguageSelected("en"),
          ),
          ListTile(
            title: const Text("Bahasa Melayu"),
            onTap: () => onLanguageSelected("ms"),
          ),
          ListTile(
            title: const Text("Bahasa Indonesia"),
            onTap: () => onLanguageSelected("id"),
          ),
          ListTile(
            title: const Text("Tagalog"),
            onTap: () => onLanguageSelected("tl"),
          ),
          ListTile(
            title: const Text("ไทย (Thai)"),
            onTap: () => onLanguageSelected("th"),
          ),
        ],
      ),
    );
  }
}
