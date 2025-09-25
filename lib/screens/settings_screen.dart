import 'package:attendance/services/options.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Options options = Options.i;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Confirm Swipe to Delete'),
            value: options.confirmSwipeToDelete,
            onChanged: (bool value) {
              setState(() {
                options.confirmSwipeToDelete = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Reload on App Resumed'),
            value: options.reloadOnAppResume,
            onChanged: (bool value) {
              setState(() {
                options.reloadOnAppResume = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Reload on Phone Call'),
            value: options.reloadOnPhoneCall,
            onChanged: (bool value) {
              setState(() {
                options.reloadOnPhoneCall = value;
              });
            },
          ),

          SwitchListTile(
            value: options.reverseColumns,
            title: const Text('Reverse Columns'),
            onChanged: (bool value) {
              setState(() {
                options.reverseColumns = value;
              });
            },
          ),
        ],
      ),
    );
  }
}
