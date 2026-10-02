import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/staged_event_models.dart';

class StagedEventEditDialog extends StatefulWidget {
  final StagedEvent event;
  final Future<void> Function(Map<String, dynamic> updatedFields) onSave;

  const StagedEventEditDialog({
    super.key,
    required this.event,
    required this.onSave,
  });

  @override
  State<StagedEventEditDialog> createState() => _StagedEventEditDialogState();
}

class _StagedEventEditDialogState extends State<StagedEventEditDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String? _errorMessage;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _enhancedTitleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _catchyDescCtrl;
  late final TextEditingController _whatsAppTeaserCtrl;
  late final TextEditingController _venueNameCtrl;
  late final TextEditingController _venueAddressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _startDateCtrl;
  late final TextEditingController _endDateCtrl;
  late final TextEditingController _startTimeCtrl;
  late final TextEditingController _endTimeCtrl;
  late final TextEditingController _minPriceCtrl;
  late final TextEditingController _maxPriceCtrl;
  late final TextEditingController _genreTagsCtrl;
  late final TextEditingController _highlightsCtrl;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleCtrl = TextEditingController(text: e.title);
    _enhancedTitleCtrl = TextEditingController(text: e.enhancedTitle ?? '');
    _descCtrl = TextEditingController(text: e.description ?? '');
    _catchyDescCtrl = TextEditingController(text: e.catchyDescription ?? '');
    _whatsAppTeaserCtrl = TextEditingController(text: e.whatsAppTeaser ?? '');
    _venueNameCtrl = TextEditingController(text: e.venueName ?? '');
    _venueAddressCtrl = TextEditingController(text: e.venueAddress ?? '');
    _cityCtrl = TextEditingController(text: e.city ?? 'Surat');
    _stateCtrl = TextEditingController(text: e.state ?? 'Gujarat');
    _startDateCtrl = TextEditingController(text: e.eventStartDate ?? '');
    _endDateCtrl = TextEditingController(text: e.eventEndDate ?? '');
    _startTimeCtrl = TextEditingController(text: e.startTime ?? '19:00');
    _endTimeCtrl = TextEditingController(text: e.endTime ?? '23:30');
    _minPriceCtrl = TextEditingController(
        text: e.minTicketPrice != null ? e.minTicketPrice!.toStringAsFixed(0) : '');
    _maxPriceCtrl = TextEditingController(
        text: e.maxTicketPrice != null ? e.maxTicketPrice!.toStringAsFixed(0) : '');
    _genreTagsCtrl = TextEditingController(text: e.genreTags.join(', '));
    _highlightsCtrl = TextEditingController(text: e.highlights.join('\n'));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _enhancedTitleCtrl.dispose();
    _descCtrl.dispose();
    _catchyDescCtrl.dispose();
    _whatsAppTeaserCtrl.dispose();
    _venueNameCtrl.dispose();
    _venueAddressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    _genreTagsCtrl.dispose();
    _highlightsCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final genreList = _genreTagsCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final highlightList = _highlightsCtrl.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final data = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'enhanced_title': _enhancedTitleCtrl.text.trim().isNotEmpty
            ? _enhancedTitleCtrl.text.trim()
            : null,
        'description': _descCtrl.text.trim().isNotEmpty ? _descCtrl.text.trim() : null,
        'catchy_description': _catchyDescCtrl.text.trim().isNotEmpty
            ? _catchyDescCtrl.text.trim()
            : null,
        'whatsapp_teaser': _whatsAppTeaserCtrl.text.trim().isNotEmpty
            ? _whatsAppTeaserCtrl.text.trim()
            : null,
        'venue_name':
            _venueNameCtrl.text.trim().isNotEmpty ? _venueNameCtrl.text.trim() : null,
        'venue_address': _venueAddressCtrl.text.trim().isNotEmpty
            ? _venueAddressCtrl.text.trim()
            : null,
        'city': _cityCtrl.text.trim().isNotEmpty ? _cityCtrl.text.trim() : null,
        'state': _stateCtrl.text.trim().isNotEmpty ? _stateCtrl.text.trim() : null,
        'event_start_date':
            _startDateCtrl.text.trim().isNotEmpty ? _startDateCtrl.text.trim() : null,
        'event_end_date':
            _endDateCtrl.text.trim().isNotEmpty ? _endDateCtrl.text.trim() : null,
        'start_time':
            _startTimeCtrl.text.trim().isNotEmpty ? _startTimeCtrl.text.trim() : null,
        'end_time':
            _endTimeCtrl.text.trim().isNotEmpty ? _endTimeCtrl.text.trim() : null,
        'min_ticket_price': double.tryParse(_minPriceCtrl.text.trim()),
        'max_ticket_price': double.tryParse(_maxPriceCtrl.text.trim()),
        'genre_tags': genreList,
        'highlights': highlightList,
      };

      await widget.onSave(data);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Staged event updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 820),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0B1E),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.neonPurple.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.neonBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: AppColors.neonBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Edit Staged Event',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Refine fields prior to live production approval',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildTextField(
                      controller: _enhancedTitleCtrl,
                      label: 'AI-Enhanced Title (Recommended)',
                      hint: 'High-energy engaging title',
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _titleCtrl,
                      label: 'Original Title *',
                      validator: (val) =>
                          (val == null || val.trim().isEmpty) ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _whatsAppTeaserCtrl,
                      label: 'WhatsApp Viral Teaser (1-liner with emojis)',
                      hint: '🔥 Don\'t miss Surat\'s biggest Garba night! Book passes now 👇',
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _catchyDescCtrl,
                      label: 'AI Marketing Description',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _descCtrl,
                      label: 'Original Event Description',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _startDateCtrl,
                            label: 'Start Date (YYYY-MM-DD)',
                            hint: '2026-10-15',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _endDateCtrl,
                            label: 'End Date (YYYY-MM-DD)',
                            hint: '2026-10-15',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _startTimeCtrl,
                            label: 'Start Time',
                            hint: '19:00',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _endTimeCtrl,
                            label: 'End Time',
                            hint: '23:30',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _venueNameCtrl,
                            label: 'Venue Name',
                            hint: 'e.g. Surat Dome Ground',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _cityCtrl,
                            label: 'City',
                            hint: 'Surat',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _venueAddressCtrl,
                      label: 'Full Address',
                      hint: 'VIP Road, Vesu, Surat',
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _minPriceCtrl,
                            label: 'Min Price (₹)',
                            hint: '499',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _maxPriceCtrl,
                            label: 'Max Price (₹)',
                            hint: '1499',
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _genreTagsCtrl,
                      label: 'Genre / Vibes (comma-separated)',
                      hint: 'Garba, Dandiya, DJ Night, Live Music',
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _highlightsCtrl,
                      label: 'Key Highlights (one per line)',
                      hint: 'AC Dome Arena\nLive Food Stalls\nFree Parking',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),

            // Modal Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F0B1E),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(
                  top: BorderSide(
                    color: AppColors.neonPurple.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.divider),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.save_rounded, size: 16),
                              SizedBox(width: 8),
                              Text('Save Staged Changes'),
                            ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 13.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFF161026),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.neonPurple, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
