// import 'dart:convert';
import 'dart:convert';

class ContactManager {
  static final ContactManager _instance = ContactManager._internal();
  factory ContactManager() => _instance;

  ContactManager._internal() {
    final contactsJson = [
      {'name': 'Test 1', 'phoneNumber': '+91-9030193157'},
      {'name': 'Test 2', 'phoneNumber': '+91-9246985559'},
      {'name': 'Vinay', 'phoneNumber': '+91-9347687479'},
      {'name': 'Jane Doe', 'phoneNumber': '+1-555-0101'},
      {'name': 'John Smith', 'phoneNumber': '+1-555-0102'},
      {'name': 'Alex Johnson', 'phoneNumber': '+1-555-0103'},
      {'name': 'Michael Brown', 'phoneNumber': '+1-555-0104'},
      {'name': 'Sarah Davis 2', 'phoneNumber': '+1-55500105'},
      {'name': 'Sarah Davis 3', 'phoneNumber': '+1-55510105'},
      {'name': 'Sarah Davis 4', 'phoneNumber': '+1-55520105'},
      {'name': 'Sarah Davis', 'phoneNumber': '+1-55530105'},
      {'name': 'Sarah Davis', 'phoneNumber': '+1-55540105'},
      {'name': 'Sarah Davis', 'phoneNumber': '+1-555990105'},
      {'name': 'Sarah Davis', 'phoneNumber': '+1-555980105'},
      {'name': 'Sarah Davis', 'phoneNumber': '+1-555970105'},
      {'name': 'Sarah Davis', 'phoneNumber': '+1-555960105'},
      {'name': 'Sarah Davis', 'phoneNumber': '+1-555950105'},
      {'name': 'Sarah Davis', 'phoneNumber': '+1-555-0105'},
      {'name': 'Sarah Davis', 'phoneNumber': '+1-555-0105'},
      {'name': 'Sarah Davis', 'phoneNumber': '+1-555-0105'},
      {'name': 'Sarah Davis', 'phoneNumber': '+1-555-0105'},
    ];

    _contacts = contactsJson.map((data) => Contact.fromMap(data)).toList();
  }

  late List<Contact> _contacts;

  List<Contact> get contacts => _contacts;

  // Utility function to clean phone numbers by removing all non-digit characters.
  String cleanPhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  // Gets a map of cleaned phone numbers to contact objects.
  Map<String, Contact> get contactsByCleanedNumber {
    return {
      for (var contact in _contacts)
        cleanPhoneNumber(contact.phoneNumber): contact,
    };
  }
}

// Contact Model to represent a single contact entry.
class Contact {
  final String name;
  final String phoneNumber;

  Contact({required this.name, required this.phoneNumber});

  static List<Contact> fromJson(String jsonString) {
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList
        .map(
          (json) =>
              Contact(name: json['name'], phoneNumber: json['phoneNumber']),
        )
        .toList();
  }

  static Contact fromMap(Map<String, dynamic> json) {
    return Contact(name: json['name'], phoneNumber: json['phoneNumber']);
  }
}
