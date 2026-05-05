import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/environment.dart';
import '../../../../core/services/auth_service.dart';

class CaregiverAlertCreateScreen extends StatefulWidget {
  const CaregiverAlertCreateScreen({super.key});

  @override
  State<CaregiverAlertCreateScreen> createState() =>
      _CaregiverAlertCreateScreenState();
}

class _CaregiverAlertCreateScreenState
    extends State<CaregiverAlertCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _messageController = TextEditingController();
  String _selectedType = 'medication';
  String _selectedPriority = 'medium';
  bool _isLoading = false;

  void _closeScreen() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/caregiver/alerts');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Alert'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _closeScreen,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTypeField(),
              const SizedBox(height: 16),
              _buildPriorityField(),
              const SizedBox(height: 16),
              _buildMessageField(),
              const Spacer(),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Alert Type', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedType,
          onChanged: (value) => setState(() => _selectedType = value!),
          items: const [
            DropdownMenuItem(value: 'medication', child: Text('Medication')),
            DropdownMenuItem(value: 'appointment', child: Text('Appointment')),
            DropdownMenuItem(value: 'emergency', child: Text('Emergency')),
            DropdownMenuItem(value: 'general', child: Text('General')),
          ],
        ),
      ],
    );
  }

  Widget _buildPriorityField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedPriority,
          onChanged: (value) => setState(() => _selectedPriority = value!),
          items: const [
            DropdownMenuItem(value: 'high', child: Text('High')),
            DropdownMenuItem(value: 'medium', child: Text('Medium')),
            DropdownMenuItem(value: 'low', child: Text('Low')),
          ],
        ),
      ],
    );
  }

  Widget _buildMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Message', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _messageController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter alert message...',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value!.isEmpty ? 'Message is required' : null,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createAlert,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Create Alert', style: TextStyle(fontSize: 16)),
      ),
    );
  }

  Future<void> _createAlert() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await AuthService().getCurrentUser();
      if (user == null) throw Exception('Not authenticated');

      final headers = await AuthService().getAuthHeaders();

      final response = await http.post(
        Uri.parse('${Environment.apiBaseUrl}/api/caregivers/alerts'),
        headers: headers,
        body: jsonEncode({
          'user_id': user.authUid ?? user.id,
          'alert_type': _selectedType,
          'message': _messageController.text,
          'priority': _selectedPriority,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alert created successfully!')),
          );
          _closeScreen();
        }
      } else {
        throw Exception('Failed to create alert: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
