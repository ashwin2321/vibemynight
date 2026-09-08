import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/loading_view.dart';
import '../widgets/admin_shell.dart';

/// Site settings form (website name, logo, WhatsApp number, phone, email,
/// socials, currency, footer text) - GET/PUT /admin/settings. This is the
/// single source of truth the public GET /settings/public endpoint serves,
/// so changing the WhatsApp number here is reflected everywhere in the
/// customer app without a rebuild.
class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _websiteName = TextEditingController();
  final _logoUrl = TextEditingController();
  final _whatsappNumber = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _instagramUrl = TextEditingController();
  final _facebookUrl = TextEditingController();
  final _currency = TextEditingController();
  final _footerText = TextEditingController();

  bool _loading = true;
  String? _loadError;
  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final settings = await ref.read(adminServiceProvider).getAdminSettings();
      _websiteName.text = settings.websiteName;
      _logoUrl.text = settings.logoUrl ?? '';
      _whatsappNumber.text = settings.whatsappNumber;
      _phone.text = settings.phone ?? '';
      _email.text = settings.email ?? '';
      _instagramUrl.text = settings.instagramUrl ?? '';
      _facebookUrl.text = settings.facebookUrl ?? '';
      _currency.text = settings.currency;
      _footerText.text = settings.footerText ?? '';
    } catch (e) {
      _loadError = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _websiteName, _logoUrl, _whatsappNumber, _phone, _email, _instagramUrl, _facebookUrl, _currency, _footerText,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    final body = {
      'websiteName': _websiteName.text.trim(),
      if (_logoUrl.text.trim().isNotEmpty) 'logoUrl': _logoUrl.text.trim(),
      'whatsappNumber': _whatsappNumber.text.trim(),
      if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
      if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
      if (_instagramUrl.text.trim().isNotEmpty) 'instagramUrl': _instagramUrl.text.trim(),
      if (_facebookUrl.text.trim().isNotEmpty) 'facebookUrl': _facebookUrl.text.trim(),
      'currency': _currency.text.trim(),
      if (_footerText.text.trim().isNotEmpty) 'footerText': _footerText.text.trim(),
    };
    try {
      await ref.read(adminServiceProvider).updateSettings(body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved')));
      }
    } catch (e) {
      setState(() => _submitError = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      title: 'Settings',
      currentPath: '/admin/settings',
      body: _loading
          ? const LoadingView()
          : _loadError != null
              ? ErrorView(message: _loadError!, onRetry: _load)
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextFormField(
                        controller: _websiteName,
                        decoration: const InputDecoration(labelText: 'Website Name *'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(controller: _logoUrl, decoration: const InputDecoration(labelText: 'Logo URL')),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _whatsappNumber,
                        decoration: const InputDecoration(
                          labelText: 'WhatsApp Number *',
                          helperText: 'International format, no + sign, e.g. 917041615131',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone')),
                      const SizedBox(height: 12),
                      TextFormField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _instagramUrl, decoration: const InputDecoration(labelText: 'Instagram URL')),
                      const SizedBox(height: 12),
                      TextFormField(
                          controller: _facebookUrl, decoration: const InputDecoration(labelText: 'Facebook URL')),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _currency,
                        decoration: const InputDecoration(labelText: 'Currency *'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _footerText,
                        decoration: const InputDecoration(labelText: 'Footer Text'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),
                      if (_submitError != null) ErrorView(message: _submitError!),
                      GradientButton(
                        label: _submitting ? 'SAVING...' : 'SAVE SETTINGS',
                        onPressed: _submitting ? null : _submit,
                      ),
                    ],
                  ),
                ),
    );
  }
}
