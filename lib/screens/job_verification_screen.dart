import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../models/job_ticket.dart';
import '../models/shop.dart';
import '../services/job_service.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

/// Mandatory live-proof capture screen. Photos come from ImageSource.camera
/// only — this is what "Mandatory Live Camera" (set in the web dashboard's
/// Setup & Customize panel) enforces: the gallery is never offered as a
/// source, so a technician cannot submit a pre-existing photo.
class JobVerificationScreen extends StatefulWidget {
  final JobTicket ticket;
  final Shop shop;

  const JobVerificationScreen({
    super.key,
    required this.ticket,
    required this.shop,
  });

  @override
  State<JobVerificationScreen> createState() => _JobVerificationScreenState();
}

class _JobVerificationScreenState extends State<JobVerificationScreen> {
  final _jobService = JobService();
  final _storageService = StorageService();
  final _locationService = LocationService();

  final Set<int> _checkedItems = {};
  XFile? _capturedImage;
  Position? _currentPosition;
  bool _isSubmitting = false;
  String? _error;

  bool get _isStartStage => widget.ticket.status == 'SCHEDULED';
  bool get _isCompletionStage => widget.ticket.status == 'IN_PROGRESS';
  bool get _isActionable => _isStartStage || _isCompletionStage;

  List<String> get _activeChecklist =>
      _isStartStage ? widget.ticket.startChecklist : widget.ticket.endChecklist;

  bool get _checklistCompleted =>
      _checkedItems.length >= _activeChecklist.length;

  Future<void> _captureLivePhotoAndGps() async {
    setState(() => _error = null);

    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera, // Hardware-enforced: no gallery picking.
        imageQuality: 80,
        maxWidth: 1280,
      );
      if (photo == null) return;

      final position = await _locationService.getCurrentPosition();

      setState(() {
        _capturedImage = photo;
        _currentPosition = position;
      });
    } catch (e) {
      setState(() => _error = 'Could not capture proof: $e');
    }
  }

  Future<void> _submit() async {
    if (!_checklistCompleted ||
        _capturedImage == null ||
        _currentPosition == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final photoUrl = await _storageService.uploadJobPhoto(
        shopId: widget.shop.id,
        ticketId: widget.ticket.id,
        file: File(_capturedImage!.path),
      );

      if (_isStartStage) {
        await _jobService.submitStartProof(
          ticketId: widget.ticket.id,
          photoUrl: photoUrl,
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
        );
      } else {
        await _jobService.submitCompletionProof(
          ticketId: widget.ticket.id,
          photoUrl: photoUrl,
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isStartStage
                ? 'Job clocked in with GPS proof!'
                : 'Job marked completed with GPS proof!',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = 'Submission failed: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    final ticket = widget.ticket;

    return Theme(
      data: buildAppTheme(shop),
      child: Scaffold(
        appBar: AppBar(title: Text(ticket.clientName)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.serviceType,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ticket.serviceAddress,
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 16),

                if (shop.mandatoryLiveCamera)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Live Snapshot Enforced — Gallery Disabled',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                if (!_isActionable) ...[
                  Text(
                    'This job is ${ticket.status}. No action needed here.',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ] else ...[
                  Text(
                    _isStartStage ? 'START TASK CHECKLIST' : 'END TASK CHECKLIST',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_activeChecklist.isEmpty)
                    const Text(
                      'No checklist items for this step.',
                      style: TextStyle(color: Colors.white54),
                    )
                  else
                    ..._activeChecklist.asMap().entries.map(
                      (entry) => CheckboxListTile(
                        value: _checkedItems.contains(entry.key),
                        onChanged: (checked) {
                          setState(() {
                            if (checked ?? false) {
                              _checkedItems.add(entry.key);
                            } else {
                              _checkedItems.remove(entry.key);
                            }
                          });
                        },
                        title: Text(
                          entry.value,
                          style: const TextStyle(color: Colors.white),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 10),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _captureLivePhotoAndGps,
                      icon: const Icon(Icons.camera_alt),
                      label: Text(
                        _capturedImage == null
                            ? (_isStartStage
                                ? 'Take Live Photo Proof + GPS Tag'
                                : 'Take Completion Photo + GPS Tag')
                            : 'Retake Photo Proof',
                      ),
                    ),
                  ),
                  if (_currentPosition != null) ...[
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'GPS Tagged: ${_currentPosition!.latitude.toStringAsFixed(4)}, '
                        '${_currentPosition!.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          (_checklistCompleted &&
                                  _capturedImage != null &&
                                  _currentPosition != null &&
                                  !_isSubmitting)
                              ? _submit
                              : null,
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isStartStage
                                  ? 'CLOCK IN & START JOB'
                                  : 'SUBMIT COMPLETION PROOF',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
