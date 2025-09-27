import 'package:attendance/screens/list_device_contacts.dart';
import 'package:attendance/services/contact_manager.dart';
import 'package:attendance/services/options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class SelectedContacts extends StatefulWidget {
  const SelectedContacts({super.key});

  @override
  State<SelectedContacts> createState() => _SelectedContactsState();
}

class _SelectedContactsState extends State<SelectedContacts>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> addFromContacts() async {
    final status = await FlutterContacts.requestPermission();
    if (!status || !mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      builder: (context) {
        return ListDeviceContacts();
      },
    ).then((_) {
      setState(() {
        // Refresh the state after returning from the bottom sheet
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final confirmDismiss = Options.i.confirmSwipeToDelete;
    return Scaffold(
      appBar: AppBar(title: const Text('Selected Contacts')),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Second floating button (appears above)
          ScaleTransition(
            scale: _animation,
            child: FloatingActionButton(
              heroTag: "btn2",
              onPressed: () {
                addFromContacts();
                _toggleExpanded();
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.person_add),
            ),
          ),
          const SizedBox(height: 10),
          // First floating button (appears above main)
          ScaleTransition(
            scale: _animation,
            child: FloatingActionButton(
              heroTag: "btn1",
              onPressed: () {
                // Add your first button action here
                print('First button pressed');
                _toggleExpanded();
              },
              backgroundColor: Colors.green,
              child: const Icon(Icons.contact_phone),
            ),
          ),
          const SizedBox(height: 10),
          // Main floating button (always visible)
          FloatingActionButton(
            heroTag: "main",
            onPressed: _toggleExpanded,
            child: AnimatedRotation(
              turns: _isExpanded ? 0.125 : 0, // 45 degrees rotation
              duration: const Duration(milliseconds: 300),
              child: Icon(_isExpanded ? Icons.close : Icons.add),
            ),
          ),
        ],
      ),
      body: ReorderableListView.builder(
        itemCount: ContactManager.instance.contacts.length,
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            ContactManager.instance.reorderContacts(oldIndex, newIndex);
          });
        },
        itemBuilder: (context, index) {
          final contact = ContactManager.instance.contacts[index];
          return Dismissible(
            key: Key('${contact.phoneNumber}_$index'),
            direction: DismissDirection.endToStart,
            crossAxisEndOffset: 0,
            dismissThresholds: {DismissDirection.endToStart: 0.5},
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Icon(Icons.delete, color: Colors.white, size: 28),
            ),
            confirmDismiss: !confirmDismiss
                ? null
                : (direction) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Delete Contact'),
                              content: Text(
                                'Are you sure you want to remove ${contact.name} from your selected contacts?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            );
                          },
                        ) ??
                        false;
                  },
            onDismissed: (direction) {
              setState(() {
                ContactManager.instance.removeContact(contact.phoneNumber);
              });

              // Clear any existing SnackBar before showing new one
              ScaffoldMessenger.of(context).clearSnackBars();

              // Show snackbar with undo option
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: cs.primaryContainer,
                  content: Text(
                    '${contact.name} removed from contacts',
                    style: TextStyle(color: cs.onPrimaryContainer),
                  ),
                  action: SnackBarAction(
                    label: 'UNDO',
                    textColor: cs.onPrimaryContainer,
                    onPressed: () {
                      setState(() {
                        ContactManager.instance.addContact(contact);
                      });
                    },
                  ),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            child: ListTile(
              title: Text(contact.name),
              subtitle: Text(contact.phoneNumber),
              trailing: const Icon(Icons.drag_handle),
            ),
          );
        },
      ),
    );
  }
}

@Preview(name: 'My Sample Text')
Widget mySampleText() {
  return const Text('Hello, World!');
}
