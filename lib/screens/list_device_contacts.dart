import 'dart:developer';

import 'package:attendance/services/contact_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ListDeviceContacts extends StatefulWidget {
  const ListDeviceContacts({super.key});

  @override
  State<ListDeviceContacts> createState() => _ListDeviceContactsState();
}

class _ListDeviceContactsState extends State<ListDeviceContacts> {
  List<Contact>? contacts;
  List<Contact> filteredContacts = [];
  List<MyContact> selectedContacts = ContactManager.instance.contacts;
  final contactsMap = ContactManager.instance.getContactMap();
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    requestPermission();
    searchController.addListener(handleSearch);
  }

  @override
  void dispose() {
    searchController.removeListener(handleSearch);
    searchController.dispose();
    super.dispose();
  }

  void handleSearch() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredContacts = contacts!
          .where(
            (contact) =>
                contact.displayName.toLowerCase().contains(query) ||
                contact.phones.any(
                  (phone) =>
                      phone.number.toLowerCase().contains(query) ||
                      phone.normalizedNumber.toLowerCase().contains(query),
                ),
          )
          .toList();
    });
  }

  addContact(Contact contact) {
    if (contact.phones.isEmpty) return;
    if (contact.phones.first.normalizedNumber.isEmpty) return;
    log(
      '${contact.phones.first.number} | ${contact.phones.first.normalizedNumber}',
    );
    final x = MyContact(
      name: contact.displayName,
      phoneNumber: contact.phones.first.normalizedNumber,
    );

    ContactManager.instance.addContact(x);
    setState(() {
      contactsMap[x.phoneNumber] = x.name;
      selectedContacts = ContactManager.instance.contacts;
    });
  }

  removeContact(String number) {
    ContactManager.instance.removeContact(number);
    setState(() {
      contactsMap.remove(number);
      selectedContacts = ContactManager.instance.contacts;
    });
  }

  void requestPermission() async {
    final status = await FlutterContacts.requestPermission();
    if (status) {
      final x = await FlutterContacts.getContacts(withProperties: true);
      setState(() {
        contacts = x
            .where(
              (c) =>
                  (c.phones.isNotEmpty &&
                  c.phones.first.normalizedNumber.isNotEmpty),
            )
            .toList();
      });
      debugPrint('Number of contacts: ${x.length}');
    } else {
      debugPrint('Permission denied');
    }
  }

  @override
  Widget build(BuildContext context) {
    // return Scaffold(
    //   // appBar: AppBar(title: const Text('Device Contacts')),
    //   body:
    // );
    // scrollaable bottom sheet
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      minChildSize: 0.5,
      maxChildSize: 0.75,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            // color: Theme.of(context).canvasColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
          ),
          child: Column(
            children: [
              // Container(
              //   margin: const EdgeInsets.symmetric(vertical: 12.0),
              //   width: 40,
              //   height: 4,
              //   decoration: BoxDecoration(
              //     color: Colors.grey[300],
              //     borderRadius: BorderRadius.circular(2),
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search Contacts',
                    isDense: true,
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(40.0)),
                    ),
                  ),
                  onChanged: (value) {},
                ),
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: contacts == null
                    ? const Center(child: Text("Loading..."))
                    : contacts!.isEmpty
                    ? const Center(child: Text('No contacts found'))
                    : buildContactList(
                        searchController.text.isEmpty
                            ? contacts
                            : filteredContacts,
                        scrollController,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildContactList(
    List<Contact>? list,
    ScrollController scrollController,
  ) {
    return ListView.builder(
      controller: scrollController,
      itemCount: list!.length,
      itemBuilder: (context, index) {
        final contact = list[index];
        final isSelected = contactsMap.containsKey(
          contact.phones.isNotEmpty
              ? contact.phones.first.normalizedNumber
              : '',
        );
        return ListTile(
          onTap: () {
            if (!isSelected) {
              addContact(contact);
            } else {
              removeContact(contact.phones.first.normalizedNumber);
            }
          },
          title: Text(contact.displayName),
          subtitle: Text(
            contact.phones.isNotEmpty
                ? contact.phones.first.normalizedNumber
                : 'No Number',
          ),
          trailing: isSelected
              ? const Icon(Icons.check, color: Colors.green)
              : null,
        );
      },
    );
  }
}
