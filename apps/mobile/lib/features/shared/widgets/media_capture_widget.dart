import 'package:flutter/material.dart';
import '../../../core/services/camera_service.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/utils/locale_format.dart';

/// Widget for capturing media (photos/videos for scanning, audio for conversations)
class MediaCaptureWidget extends StatefulWidget {
  final Function(String?)? onPhotoCaptured;
  final Function(String?)? onAudioRecorded;

  const MediaCaptureWidget({
    super.key,
    this.onPhotoCaptured,
    this.onAudioRecorded,
  });

  @override
  State<MediaCaptureWidget> createState() => _MediaCaptureWidgetState();
}

class _MediaCaptureWidgetState extends State<MediaCaptureWidget> {
  final CameraService _cameraService = CameraService();
  final AudioService _audioService = AudioService();

  @override
  void initState() {
    super.initState();
    // Initialize services
    _cameraService.initialize();
  }

  @override
  void dispose() {
    _audioService.dispose();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medical Media Capture',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Camera Section
            _buildCameraSection(),

            const Divider(height: 32),

            // Audio Section
            _buildAudioSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.camera_alt,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Scan Documents',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Take photos of pill bottles, lab reports, prescriptions, or medical documents',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _scanWithCamera,
                icon: const Icon(Icons.camera),
                label: const Text('Take Photo'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('From Gallery'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAudioSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.mic,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Record Conversations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Record healthcare consultations, medication instructions, or important discussions',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Recording Controls
        if (_audioService.isRecording)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.radio_button_checked, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Recording: ${_audioService.getFormattedDuration(LocaleFormat.locale(context))}',
                  style: const TextStyle(
                      color: Colors.red, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _stopRecording,
                  icon: const Icon(Icons.stop, color: Colors.red),
                  tooltip: 'Stop Recording',
                ),
              ],
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startRecording,
              icon: const Icon(Icons.mic),
              label: const Text('Start Recording'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Recording History (placeholder)
        Row(
          children: [
            const Icon(Icons.history, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Recent Recordings',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _scanWithCamera() async {
    try {
      final imagePath = await _cameraService.scanDocument(context);
      if (imagePath != null) {
        widget.onPhotoCaptured?.call(imagePath);
        _showSuccessSnackBar('Document scanned successfully!');

        // Clean up temporary image file after processing
        await _cameraService.cleanupImageFile(imagePath);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to scan document: ${e.toString()}');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final image = await _cameraService.pickFromGallery(context);
      if (image != null) {
        widget.onPhotoCaptured?.call(image.path);
        _showSuccessSnackBar('Image selected successfully!');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to select image: ${e.toString()}');
    }
  }

  Future<void> _startRecording() async {
    final success = await _audioService.startRecording(context);
    if (success) {
      setState(() {}); // Trigger rebuild to show recording state
      _showSuccessSnackBar('Recording started...');
    } else {
      _showErrorSnackBar('Microphone permission is required to record audio.');
    }
  }

  Future<void> _stopRecording() async {
    final recordingPath = await _audioService.stopRecording();
    if (recordingPath != null) {
      setState(() {}); // Trigger rebuild to hide recording state
      widget.onAudioRecorded?.call(recordingPath);
      _showSuccessSnackBar('Recording saved successfully!');
    } else {
      setState(() {}); // Trigger rebuild to hide recording state
      _showErrorSnackBar('Failed to save recording.');
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
