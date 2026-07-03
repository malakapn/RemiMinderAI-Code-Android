import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/locale_format.dart';
import '../../../../l10n/app_localizations.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  // Emergency contacts data
  final List<Map<String, dynamic>> _emergencyContacts = [
    {
      'id': '1',
      'name': 'Emergency Services',
      'phone': '911',
      'type': 'emergency',
      'priority': 1,
      'isSystem': true,
    },
    {
      'id': '2',
      'name': 'John Doe (Spouse)',
      'phone': '(555) 123-4567',
      'type': 'family',
      'priority': 2,
      'relationship': 'Spouse',
      'isSystem': false,
    },
    {
      'id': '3',
      'name': 'Dr. Sarah Johnson',
      'phone': '(555) 987-6543',
      'type': 'medical',
      'priority': 3,
      'specialty': 'Cardiology',
      'isSystem': false,
    },
    {
      'id': '4',
      'name': 'Jane Smith (Sister)',
      'phone': '(555) 456-7890',
      'type': 'family',
      'priority': 4,
      'relationship': 'Sister',
      'isSystem': false,
    },
  ];

  String _medicalAlertInfo =
      'Cardiac patient, allergic to penicillin, takes daily medications';

  final List<String> _contactTypes = ['family', 'medical', 'friend', 'other'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => context.go('/patient/home'),
        ),
        title: const Text(
          'Emergency Contacts',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _showAddContactDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Emergency SOS Button
            Container(
              margin: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: _triggerEmergencySOS,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: Colors.red.withOpacity(0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.emergency,
                      size: 32,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        const Text(
                          'EMERGENCY SOS',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'Call all emergency contacts',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Medical Alert Info
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.medical_information,
                    color: Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Medical Alert Information',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _medicalAlertInfo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[700],
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _editMedicalInfo,
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Contacts List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _emergencyContacts.length,
                itemBuilder: (context, index) {
                  final contact = _emergencyContacts[index];
                  return _buildContactCard(contact);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact) {
    final type = contact['type'] as String;
    final isSystem = contact['isSystem'] as bool;
    final priority = contact['priority'] as int;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Priority indicator
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _getPriorityColor(priority),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  LocaleFormat.number(context, priority),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Contact icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getTypeColor(type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getTypeIcon(type),
                color: _getTypeColor(type),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Contact details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    contact['phone'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  if (contact['relationship'] != null || contact['specialty'] != null)
                    Text(
                      contact['relationship'] ?? contact['specialty'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),

            // Action buttons
            Row(
              children: [
                IconButton(
                  onPressed: () => _callContact(contact),
                  icon: const Icon(
                    Icons.call,
                    color: Colors.green,
                    size: 20,
                  ),
                ),
                if (!isSystem)
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleContactAction(contact, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'emergency':
        return Colors.red;
      case 'family':
        return Colors.green;
      case 'medical':
        return Colors.blue;
      case 'friend':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'emergency':
        return Icons.emergency;
      case 'family':
        return Icons.family_restroom;
      case 'medical':
        return Icons.medical_services;
      case 'friend':
        return Icons.people;
      default:
        return Icons.person;
    }
  }

  void _triggerEmergencySOS() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.emergency,
              color: Colors.red,
              size: 28,
            ),
            SizedBox(width: 8),
            Text('Emergency SOS'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This will call ALL emergency contacts simultaneously. Are you sure?',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Emergency contacts will be called in priority order',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _executeEmergencySOS();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Call Emergency Contacts'),
          ),
        ],
      ),
    );
  }

  void _executeEmergencySOS() {
    // TODO: Implement actual emergency calling logic
    // This would call contacts in priority order
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency SOS activated! Calling all contacts...'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _callContact(Map<String, dynamic> contact) {
    // TODO: Implement actual calling functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling ${contact['name']}...')),
    );
  }

  void _handleContactAction(Map<String, dynamic> contact, String action) {
    switch (action) {
      case 'edit':
        _showEditContactDialog(contact);
        break;
      case 'delete':
        _showDeleteContactDialog(contact);
        break;
    }
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedType = 'family';
    String relationship = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.person_add,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text('Add Emergency Contact'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter contact name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '(555) 123-4567',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Contact Type',
                  ),
                  items: _contactTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type[0].toUpperCase() + type.substring(1)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedType = value!);
                  },
                ),
                if (selectedType == 'family') ...[
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) => relationship = value,
                    decoration: const InputDecoration(
                      labelText: 'Relationship',
                      hintText: 'Spouse, Child, Parent, etc.',
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                  _addContact(
                    nameController.text,
                    phoneController.text,
                    selectedType,
                    relationship,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add Contact'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditContactDialog(Map<String, dynamic> contact) {
    if (contact['isSystem'] == true) return;

    final nameController = TextEditingController(text: contact['name'] as String? ?? '');
    final phoneController = TextEditingController(text: contact['phone'] as String? ?? '');
    final relationshipController =
        TextEditingController(text: contact['relationship'] as String? ?? '');
    String selectedType = (contact['type'] as String?) ?? 'family';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Emergency Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Contact Type'),
                  items: _contactTypes
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                                type[0].toUpperCase() + type.substring(1)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => selectedType = value);
                  },
                ),
                if (selectedType == 'family') ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: relationshipController,
                    decoration: const InputDecoration(
                      labelText: 'Relationship',
                      hintText: 'Spouse, Child, Parent, etc.',
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                  return;
                }
                final relationship = relationshipController.text.trim();
                setState(() {
                  contact['name'] = nameController.text.trim();
                  contact['phone'] = phoneController.text.trim();
                  contact['type'] = selectedType;
                  contact['relationship'] =
                      relationship.isNotEmpty ? relationship : null;
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contact updated')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _editMedicalInfo() {
    final controller = TextEditingController(text: _medicalAlertInfo);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Medical Alert Information'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Allergies, conditions, medications...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _medicalAlertInfo = controller.text.trim().isEmpty
                    ? 'No medical alerts recorded'
                    : controller.text.trim();
              });
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteContactDialog(Map<String, dynamic> contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text(
            'Are you sure you want to remove ${contact['name']} from emergency contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _emergencyContacts.remove(contact);
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contact removed')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addContact(
      String name, String phone, String type, String relationship) {
    final newContact = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'phone': phone,
      'type': type,
      'priority': _emergencyContacts.length + 1,
      'relationship': relationship.isNotEmpty ? relationship : null,
      'isSystem': false,
    };

    setState(() {
      _emergencyContacts.add(newContact);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name added to emergency contacts')),
    );
  }
}
