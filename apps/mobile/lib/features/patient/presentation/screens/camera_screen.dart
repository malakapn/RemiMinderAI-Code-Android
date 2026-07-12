import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/legal_urls.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/backend_api_service.dart';

class CameraScreen extends StatefulWidget {
  final ScanMode? initialMode;
  final String visitId;

  const CameraScreen({
    super.key,
    this.initialMode,
    required this.visitId,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

ScanMode _parseScanMode(String? modeString) {
  switch (modeString) {
    case 'labReport':
      return ScanMode.labReport;
    case 'medication':
      return ScanMode.medication;
    case 'prescription':
    default:
      return ScanMode.prescription;
  }
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  static const String _consentVersion = 'v1';
  static final Uri _privacyPolicyUri = Uri.parse(LegalUrls.privacy);

  late AnimationController _processingController;

  late ScanMode _selectedMode;
  ScanState _scanState = ScanState.ready;
  Map<String, dynamic>? _scanResults;
  Timer? _scanTimer;
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BackendApiService _backendApiService = BackendApiService();

  // Camera related
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  String? _lastCapturedImagePath;
  String? _lastGcsFilePath;
  bool _scanConsentGiven = false;
  bool _isStartingScan = false;

  @override
  void initState() {
    super.initState();

    // Initialize selected mode based on parameter or default
    _selectedMode = widget.initialMode ?? ScanMode.prescription;

    // Check for mode from query parameters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final router = GoRouter.of(context);
      final location = router.routerDelegate.currentConfiguration.uri;
      final modeString = location.queryParameters['mode'];
      if (modeString != null) {
        setState(() {
          _selectedMode = _parseScanMode(modeString);
        });
      }
    });

    _processingController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
  }

  Future<bool> _initializeCamera() async {
    if (_isCameraInitialized && _cameraController != null) {
      return true;
    }

    try {
      // Get available cameras
      final cameras = await availableCameras();

      // Select back camera (preferred for document scanning)
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first, // Fallback to first available
      );

      // Create camera controller
      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high, // High resolution for document scanning
        enableAudio: false, // No audio needed for scanning
      );

      // Initialize camera
      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
      return true;
    } catch (e) {
      // Camera initialization failed, but don't block the app
      // User can still use the scan interface (though it won't work)
      return false;
    }
  }

  @override
  void dispose() {
    _processingController.dispose();
    _scanTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.close,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () => context.go('/patient/home'),
        ),
        actions: [
          if (_scanState == ScanState.completed)
            TextButton(
              onPressed: _saveScan,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: _scanState == ScanState.completed
          ? _buildResultsView()
          : _buildCameraView(),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        // Full-screen Camera Preview
        Positioned.fill(
          child: () {
            final shouldShowPreview =
                _isCameraInitialized && _cameraController != null;
            return shouldShowPreview
                ? CameraPreview(_cameraController!)
                : Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white54,
                        size: 80,
                      ),
                    ),
                  );
          }(),
        ),

        // Scan Frame (subtle overlay)
        if (_scanState == ScanState.ready)
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

        // Mode Selector (top center, subtle)
        Positioned(
          top: 120,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCompactModeButton(ScanMode.prescription, 'Rx'),
                _buildCompactModeButton(ScanMode.labReport, 'Lab'),
                _buildCompactModeButton(ScanMode.medication, 'Med'),
              ],
            ),
          ),
        ),

        // Capture Button (bottom center)
        Positioned(
          bottom: 40,
          left: 24,
          right: 24,
          child: _isCameraInitialized
              ? Column(
                  children: [
                    // Capture Button
                    GestureDetector(
                      onTap:
                          _scanState == ScanState.ready ? _captureImage : null,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _scanState == ScanState.scanning
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white,
                            width: 4,
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _scanState == ScanState.scanning
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Helper Text
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _scanState == ScanState.ready
                            ? 'Tap to capture'
                            : 'Processing...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildConsentBlock(),
                    const SizedBox(height: 16),
                    _buildScanButton(),
                  ],
                ),
        ),

        // Processing Indicator
        if (_scanState == ScanState.processing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Processing image...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConsentBlock() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.14),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consent required before scanning',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const _ScanConsentCheckboxTileSpacer(),
          _ScanConsentCheckboxTile(
            value: _scanConsentGiven,
            enabled: !_isStartingScan,
            onChanged: (value) {
              setState(() {
                _scanConsentGiven = value;
              });
            },
            onPrivacyPolicyTap: _openPrivacyPolicy,
          ),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    final canStartScan = _scanConsentGiven && !_isStartingScan;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canStartScan ? _startScanSession : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          disabledBackgroundColor: Colors.grey.shade600,
          disabledForegroundColor: Colors.white70,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: _isStartingScan
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Scan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildResultsView() {
    if (_scanResults == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.green.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan Successful!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          _getResultTitle(),
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Results
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildScanResults(),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareScan,
                      icon: const Icon(Icons.share),
                      label: Text(AppLocalizations.of(context)!.share),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveScan,
                      icon: const Icon(Icons.save),
                      label: Text(AppLocalizations.of(context)!.save),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanResults() {
    // Show processing state — real OCR happens on backend after Save
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Document captured',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap Save to process this document. Results will appear in Overview → Scanned Docs.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResultSection('Prescription Details', [
          _buildResultItem('Medication', 'Lisinopril'),
          _buildResultItem('Dosage', '10mg'),
          _buildResultItem('Frequency', 'Once daily'),
          _buildResultItem('Quantity', '90 tablets'),
          _buildResultItem('Refills', '3 remaining'),
        ]),
        const SizedBox(height: 24),
        _buildResultSection('Prescriber Information', [
          _buildResultItem('Doctor', 'Dr. Sarah Johnson'),
          _buildResultItem('License', 'MD123456'),
          _buildResultItem('Date', 'Dec 12, 2024'),
        ]),
        const SizedBox(height: 24),
        _buildResultSection('Pharmacy Information', [
          _buildResultItem('Pharmacy', 'City Medical Pharmacy'),
          _buildResultItem('Phone', '(555) 123-4567'),
          _buildResultItem('Address', '123 Main St, City, ST 12345'),
        ]),
      ],
    );
  }

  Widget _buildLabReportResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResultSection('Patient Information', [
          _buildResultItem('Name', 'John Doe'),
          _buildResultItem('DOB', '01/15/1985'),
          _buildResultItem('ID', 'P123456789'),
        ]),
        const SizedBox(height: 24),
        _buildResultSection('Test Results', [
          _buildResultItem('Cholesterol (Total)', '185 mg/dL', 'Normal: <200'),
          _buildResultItem('HDL Cholesterol', '45 mg/dL', 'Normal: >40'),
          _buildResultItem('LDL Cholesterol', '120 mg/dL', 'Normal: <130'),
          _buildResultItem('Triglycerides', '150 mg/dL', 'Normal: <150'),
        ]),
        const SizedBox(height: 24),
        _buildResultSection('Lab Information', [
          _buildResultItem('Lab', 'City Medical Labs'),
          _buildResultItem('Report Date', 'Dec 10, 2024'),
          _buildResultItem('Collected', 'Dec 9, 2024'),
        ]),
      ],
    );
  }

  Widget _buildMedicationResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildResultSection('Medication Information', [
          _buildResultItem('Name', 'Lisinopril'),
          _buildResultItem('Strength', '10mg'),
          _buildResultItem('Form', 'Tablet'),
          _buildResultItem('Quantity', '90 tablets'),
        ]),
        const SizedBox(height: 24),
        _buildResultSection('Usage Instructions', [
          _buildResultItem('Directions', 'Take one tablet by mouth once daily'),
          _buildResultItem('Purpose', 'Blood pressure management'),
          _buildResultItem('Storage', 'Store at room temperature'),
        ]),
        const SizedBox(height: 24),
        _buildResultSection('Additional Information', [
          _buildResultItem('Manufacturer', 'Generic Pharmaceuticals'),
          _buildResultItem('Lot Number', 'LP2024001'),
          _buildResultItem('Expiration', '06/2026'),
        ]),
      ],
    );
  }

  Widget _buildResultSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }

  Widget _buildResultItem(String label, String value, [String? reference]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (reference != null)
                  Text(
                    reference,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _captureImage() async {
    if (!_isCameraInitialized || _cameraController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.cameraNotReady)),
      );
      return;
    }

    try {
      setState(() {
        _scanState = ScanState.scanning;
      });

      // Take picture with camera
      final XFile imageFile = await _cameraController!.takePicture();

      // Save to app-controlled storage
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPath = '${directory.path}/scan_$timestamp.jpg';
      await imageFile.saveTo(newPath);

      _lastCapturedImagePath = newPath;

      // Complete the scan process
      _completeScan();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanState = ScanState.ready;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.failedToCaptureImage('$e'))),
      );
    }
  }

  Future<void> _startScanSession() async {
    if (!_scanConsentGiven || _isStartingScan || _isCameraInitialized) {
      return;
    }

    setState(() {
      _isStartingScan = true;
    });

    try {
      await _logScanConsent();
      if (!mounted) return;

      final initialized = await _initializeCamera();
      if (!mounted) return;

      if (!initialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.unableToStartCamera),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.cameraReadyHint),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.unableToStartScanning('$e'))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isStartingScan = false;
        });
      }
    }
  }

  Future<void> _logScanConsent() async {
    final currentUser = await _authService.getCurrentUser();
    final uid = currentUser?.authUid ?? currentUser?.id;

    if (uid == null || uid.isEmpty) {
      throw Exception('Please sign in again before scanning.');
    }

    final sessionId = DateTime.now().toUtc().millisecondsSinceEpoch.toString();

    await _firestore
        .collection('consents')
        .doc(uid)
        .collection('scan_sessions')
        .doc(sessionId)
        .set({
      'scanConsentGiven': true,
      'consentVersion': _consentVersion,
      'platform': _platformLabel,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  String get _platformLabel {
    if (Platform.isIOS) {
      return 'ios';
    }
    if (Platform.isAndroid) {
      return 'android';
    }
    return Platform.operatingSystem;
  }

  Future<void> _openPrivacyPolicy() async {
    try {
      final launched = await launchUrl(
        _privacyPolicyUri,
        mode: LaunchMode.inAppBrowserView,
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.unableToOpenPrivacyPolicy)),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.unableToOpenPrivacyPolicy)),
      );
    }
  }

  void _completeScan() {
    setState(() {
      _scanState = ScanState.processing;
    });

    // Simulate processing time
    Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;
      setState(() {
        _scanState = ScanState.completed;
        _scanResults = _generateMockResults();
      });

      // Upload image to backend
      if (_lastCapturedImagePath != null) {
        try {
          final gcsPath = await _backendApiService.uploadImage(
            visitId: widget.visitId,
            imageFile: File(_lastCapturedImagePath!),
          );
          _lastGcsFilePath = gcsPath;
          if (!mounted) return;
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.failedToUploadImage('$e'))),
          );
          _lastCapturedImagePath = null;
          return;
        }
      }

      // Clean up the captured image file after processing/upload
      if (_lastCapturedImagePath != null) {
        try {
          final file = File(_lastCapturedImagePath!);
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (e) {
          // Silent cleanup failure
        }
        _lastCapturedImagePath = null;
      }
    });
  }

  Map<String, dynamic> _generateMockResults() {
    // Generate mock results based on scan mode
    return {
      'scanMode': _selectedMode,
      'timestamp': DateTime.now(),
      'confidence': 0.95,
    };
  }

  void _saveScan() async {
    if (_lastGcsFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.noImageToProcess)),
      );
      return;
    }

    // Show processing indicator
    setState(() => _scanState = ScanState.processing);

    try {
      await _backendApiService.scanDocument(gcsFilePath: _lastGcsFilePath!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.documentScannedSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.scanProcessingFailed('$e'))),
      );
    }

    if (!mounted) return;
    // Navigate to Overview tab (index 2) so user sees scanned doc
    context.go('/patient/overview');
  }

  void _shareScan() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.scanSavedToHistory)),
    );
    context.go('/patient/overview');
  }

  String _getResultTitle() {
    switch (_selectedMode) {
      case ScanMode.prescription:
        return 'Prescription scanned successfully';
      case ScanMode.labReport:
        return 'Lab report processed successfully';
      case ScanMode.medication:
        return 'Medication information extracted';
    }
  }

  Widget _buildCompactModeButton(ScanMode mode, String label) {
    final isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: _scanState == ScanState.ready
          ? () => setState(() => _selectedMode = mode)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _ScanConsentCheckboxTileSpacer extends StatelessWidget {
  const _ScanConsentCheckboxTileSpacer();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Review and accept the consent below to enable scanning.',
      style: TextStyle(
        color: Theme.of(context).colorScheme.secondary,
        fontSize: 13,
        height: 1.3,
      ),
    );
  }
}

class _ScanConsentCheckboxTile extends StatelessWidget {
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final VoidCallback onPrivacyPolicyTap;

  const _ScanConsentCheckboxTile({
    required this.value,
    required this.enabled,
    required this.onChanged,
    required this.onPrivacyPolicyTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Checkbox(
                    value: value,
                    onChanged: enabled
                        ? (checked) => onChanged(checked ?? false)
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.cameraScanAiConsent,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: enabled ? onPrivacyPolicyTap : null,
                        style: TextButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          foregroundColor: theme.colorScheme.primary,
                          minimumSize: const Size(44, 44),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum ScanMode {
  prescription,
  labReport,
  medication,
}

enum ScanState {
  ready,
  scanning,
  processing,
  completed,
}

class ScanLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  ScanLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final y = size.height * progress;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      paint,
    );
  }

  @override
  bool shouldRepaint(ScanLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
