// import 'dart:convert';
import 'dart:convert';

import 'package:attendance/main.dart';

class ContactManager {
  static final ContactManager instance = ContactManager._internal();
  factory ContactManager._() => instance;

  ContactManager._internal() {
    final contactsJson = prefs!.getString('contacts') ?? '[]';

    _contacts = (json.decode(contactsJson) as List)
        .map((data) => MyContact.fromMap(data))
        .toList();
    // _contactsMap = {
    //   for (var contact in _contacts) contact.phoneNumber: contact.name,
    // };
  }

  late List<MyContact> _contacts;
  // late Map<String, String> _contactsMap;

  List<MyContact> get contacts => _contacts;
  // Map<String, String> get contactsMap => _contactsMap;

  Map<String, String> getContactMap() {
    return {for (var contact in _contacts) contact.phoneNumber: contact.name};
  }

  addContact(MyContact contact) {
    _contacts.add(contact);
    // _contactsMap[contact.phoneNumber] = contact.name;
    updateSavedPrefs();
  }

  removeContact(String number) {
    _contacts.removeWhere((contact) => contact.phoneNumber == number);
    // _contactsMap.remove(number);
    updateSavedPrefs();
  }

  reorderContacts(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final MyContact item = _contacts.removeAt(oldIndex);
    _contacts.insert(newIndex, item);

    // Save to preferences
    updateSavedPrefs();
  }

  updateSavedPrefs() {
    final contactsJson = json.encode(
      _contacts
          .map((c) => {'name': c.name, 'phoneNumber': c.phoneNumber})
          .toList(),
    );
    prefs!.setString('contacts', contactsJson);
  }
}

// Contact Model to represent a single contact entry.
class MyContact {
  final String name;
  final String phoneNumber;

  MyContact({required this.name, required this.phoneNumber});

  static List<MyContact> fromJson(String jsonString) {
    final List<dynamic> jsonList = json.decode(jsonString);
    return jsonList
        .map(
          (json) =>
              MyContact(name: json['name'], phoneNumber: json['phoneNumber']),
        )
        .toList();
  }

  static MyContact fromMap(Map<String, dynamic> json) {
    return MyContact(name: json['name'], phoneNumber: json['phoneNumber']);
  }
}
