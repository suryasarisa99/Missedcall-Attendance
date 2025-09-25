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
            value: Options.confirmSwipeToDelete,
            onChanged: (bool value) {
              setState(() {
                Options.confirmSwipeToDelete = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Reload on App Resumed'),
            value: Options.reloadOnAppResume,
            onChanged: (bool value) {
              setState(() {
                Options.reloadOnAppResume = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Reload on Phone Call'),
            value: Options.reloadOnPhoneCall,
            onChanged: (bool value) {
              setState(() {
                Options.reloadOnPhoneCall = value;
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
