import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/admin_providers.dart';
import '../../../core/providers/dome_layout_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../models/event_detail.dart';
import '../widgets/admin_shell.dart';
import '../widgets/image_upload_field.dart';

/// Single form reused for both Create Event and Edit Event, per the spec's
/// shared field list (name, slug, images, description, dates, venue,
/// address, city, location, google maps url, organizer, contact, featured).
class AdminCreateEventScreen extends StatelessWidget {
  const AdminCreateEventScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminEventForm();
}

class AdminEditEventScreen extends ConsumerWidget {
  final int eventId;

  const AdminEditEventScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(adminEventDetailProvider(eventId));
    return eventAsync.when(
      loading: () => const AdminShell(title: 'Edit Event', currentPath: '/admin/events', body: LoadingView()),
      error: (err, _) => AdminShell(
        title: 'Edit Event',
        currentPath: '/admin/events',
        body: ErrorView(message: err.toString(), onRetry: () => ref.invalidate(adminEventDetailProvider(eventId))),
      ),
      data: (event) => _AdminEventForm(eventId: eventId, initial: event),
    );
  }
}

class _AdminEventForm extends ConsumerStatefulWidget {
  final int? eventId;
  final EventDetail? initial;

  const _AdminEventForm({this.eventId, this.initial});

  @override
  ConsumerState<_AdminEventForm> createState() => _AdminEventFormState();
}

class _AdminEventFormState extends ConsumerState<_AdminEventForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _slug;
  late final TextEditingController _mainImage;
  late final TextEditingController _banner;
  late final TextEditingController _thumbnail;
  late final TextEditingController _description;
  late final TextEditingController _startDate;
  late final TextEditingController _endDate;
  late final TextEditingController _venue;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _location;
  late final TextEditingController _googleMapsUrl;
  late final TextEditingController _organizer;
  late final TextEditingController _contactNumber;
  late final TextEditingController _email;
  bool _featured = false;
  bool _hasDomeLayout = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.initial;
    _name = TextEditingController(text: e?.name ?? '');
    _slug = TextEditingController(text: e?.slug ?? '');
    _mainImage = TextEditingController(text: e?.mainImage ?? '');
    _banner = TextEditingController(text: e?.banner ?? '');
    _thumbnail = TextEditingController(text: e?.thumbnail ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _startDate = TextEditingController(text: e?.startDate ?? '');
    _endDate = TextEditingController(text: e?.endDate ?? '');
    _venue = TextEditingController(text: e?.venue ?? '');
    _address = TextEditingController(text: e?.address ?? '');
    _city = TextEditingController(text: e?.city ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _googleMapsUrl = TextEditingController(text: e?.googleMapsUrl ?? '');
    _organizer = TextEditingController(text: e?.organizer ?? '');
    _contactNumber = TextEditingController(text: e?.contactNumber ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _featured = e?.featured ?? false;
    _hasDomeLayout = e != null &&
        (ref.read(domeLayoutProvider).isEnabledFor(e) ||
            e.rules.contains('FEATURE_DOME_LAYOUT') ||
            e.highlights.contains('FEATURE_DOME_LAYOUT') ||
            e.name.toLowerCase().contains('ac dome') ||
            (e.venue?.toLowerCase().contains('dome') ?? false));
  }

  @override
  void dispose() {
    for (final c in [
      _name, _slug, _mainImage, _banner, _thumbnail, _description, _startDate, _endDate,
      _venue, _address, _city, _location, _googleMapsUrl, _organizer, _contactNumber, _email,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = picked.toIso8601String().split('T').first;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final mainImg = _mainImage.text.trim();
    final bannerImg = _banner.text.trim().isNotEmpty ? _banner.text.trim() : mainImg;
    final thumbImg = _thumbnail.text.trim().isNotEmpty ? _thumbnail.text.trim() : mainImg;

    final body = {
      'name': _name.text.trim(),
      'slug': _slug.text.trim(),
      if (mainImg.isNotEmpty) 'mainImage': mainImg,
      if (bannerImg.isNotEmpty) 'banner': bannerImg,
      if (thumbImg.isNotEmpty) 'thumbnail': thumbImg,
      if (_description.text.trim().isNotEmpty) 'description': _description.text.trim(),
      'startDate': _startDate.text.trim(),
      'endDate': _endDate.text.trim(),
      if (_venue.text.trim().isNotEmpty) 'venue': _venue.text.trim(),
      if (_address.text.trim().isNotEmpty) 'address': _address.text.trim(),
      if (_city.text.trim().isNotEmpty) 'city': _city.text.trim(),
      if (_location.text.trim().isNotEmpty) 'location': _location.text.trim(),
      if (_googleMapsUrl.text.trim().isNotEmpty) 'googleMapsUrl': _googleMapsUrl.text.trim(),
      if (_organizer.text.trim().isNotEmpty) 'organizer': _organizer.text.trim(),
      if (_contactNumber.text.trim().isNotEmpty) 'contactNumber': _contactNumber.text.trim(),
      if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
      'featured': _featured,
    };
    try {
      final admin = ref.read(adminServiceProvider);
      if (widget.eventId != null) {
        await admin.updateEvent(widget.eventId!, body);
        await ref.read(domeLayoutProvider.notifier).setEventDomeLayout(
          eventId: widget.eventId,
          slug: _slug.text.trim(),
          enabled: _hasDomeLayout,
        );
      } else {
        await admin.createEvent(body);
        await ref.read(domeLayoutProvider.notifier).setEventDomeLayout(
          slug: _slug.text.trim(),
          enabled: _hasDomeLayout,
        );
      }
      ref.invalidate(adminEventsProvider);
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.eventId != null;
    return AdminShell(
      title: isEdit ? 'Edit Event' : 'Create Event',
      currentPath: '/admin/events',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Event Name *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _slug,
              decoration: const InputDecoration(labelText: 'Slug *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startDate,
                    readOnly: true,
                    onTap: () => _pickDate(_startDate),
                    decoration: const InputDecoration(labelText: 'Start Date *'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _endDate,
                    readOnly: true,
                    onTap: () => _pickDate(_endDate),
                    decoration: const InputDecoration(labelText: 'End Date *'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            ImageUploadField(controller: _mainImage, label: 'Main Image URL', folder: 'events'),
            const SizedBox(height: 12),
            ImageUploadField(controller: _banner, label: 'Banner URL', folder: 'events'),
            const SizedBox(height: 12),
            ImageUploadField(controller: _thumbnail, label: 'Thumbnail URL', folder: 'events'),
            const SizedBox(height: 12),
            TextFormField(controller: _venue, decoration: const InputDecoration(labelText: 'Venue')),
            const SizedBox(height: 12),
            TextFormField(controller: _address, decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(controller: _city, decoration: const InputDecoration(labelText: 'City')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                      controller: _location, decoration: const InputDecoration(labelText: 'Location')),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
                controller: _googleMapsUrl, decoration: const InputDecoration(labelText: 'Google Maps URL')),
            const SizedBox(height: 12),
            TextFormField(controller: _organizer, decoration: const InputDecoration(labelText: 'Organizer')),
            const SizedBox(height: 12),
            TextFormField(
                controller: _contactNumber, decoration: const InputDecoration(labelText: 'Contact Number')),
            const SizedBox(height: 12),
            TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Row(
                children: [
                  Icon(Icons.stadium_outlined, color: AppColors.neonPurple, size: 20),
                  SizedBox(width: 8),
                  Text('AC Dome / Stadium Layout Map', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              subtitle: const Text('Renders interactive visual stage, fanpit, diamond, gold stands & price filter map on event booking page'),
              value: _hasDomeLayout,
              onChanged: (v) => setState(() => _hasDomeLayout = v),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Featured Event'),
              value: _featured,
              onChanged: (v) => setState(() => _featured = v),
            ),
            const SizedBox(height: 20),
            if (_error != null) ErrorView(message: _error!),
            GradientButton(
              label: _submitting ? 'SAVING...' : (isEdit ? 'SAVE CHANGES' : 'CREATE EVENT'),
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
